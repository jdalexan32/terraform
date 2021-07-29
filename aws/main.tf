# Configure AWS Provider source and version being used
# https://registry.terraform.io/providers/hashicorp/aws/latest/
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
}

# Configure AWS Provider and options
provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"
  
  cidr = var.vpc_cidr_block

  
  azs             = data.aws_availability_zones.available.names                           # ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnets_per_vpc) # for internet-facing Load Balancer to private subnets need Internet Gateway attached to subnets
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnets_per_vpc)

  enable_nat_gateway = true
  enable_vpn_gateway = false
   
  vpc_tags = {
    Name = "${var.project_name}-vpc"
  }

}

module "private_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"
  
  name        = "${var.project_name}-private-ec2-sg"
  description = "Allows HTTP (80/8080) ingress from public subnets, open ingress from private_ec2_security_group, and open egress"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks
  ingress_rules       = [
    "http-80-tcp",
    "http-8080-tcp",
  ]
      
  /*
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  */
  
  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.private_ec2_security_group.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

module "public_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"
  
  name        = "${var.project_name}-public-ec2-sg"
  description = "Allows SSH and HTTP ingress from internet, open ingress from public_ec2_security_group (self), and open egress"
  vpc_id      = module.vpc.vpc_id
   
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = [
    "http-80-tcp",
  ]

  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]
  
  /* BELOW RULE IS EQUIVELANT TO ABOVE ingress_with_self RULE
  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.public_ec2_security_group.security_group_id
    }
  ]
  */

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"
  
  name        = "${var.project_name}-lb-sg"
  description = "Allow HTTP ingress from the internet and open egress"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = [
    "http-80-tcp",
    "http-8080-tcp",
    ]
  
  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.lb_security_group.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}
/*

!!THIS MODULE DEPLOYES CLASSIC ELB

resource "random_string" "lb_id" {
  length  = 4
  special = false
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  # Comply with ELB name restrictions 
  # https://docs.aws.amazon.com/elasticloadbalancing/2012-06-01/APIReference/API_CreateLoadBalancer.html
  name     = trimsuffix(substr(replace(join("-", ["lb", random_string.lb_id.result, var.project_name]), "/[^a-zA-Z0-9-]/", ""), 0, 32), "-")
  internal = false

  security_groups = [module.lb_security_group.security_group_id]
  subnets         = module.vpc.public_subnets

  number_of_instances = length(aws_instance.linux)
  instances           = aws_instance.linux.*.id
  
  listener = [{
    instance_port     = "80"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }]

  health_check = {
    target              = "HTTP:80/index.html"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
  }
}
*/

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name               = "${var.project_name}-lb"
  load_balancer_type = "application"
  
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.lb_security_group.security_group_id]

  tags = {
    Name = "${var.project_name}-lb"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  
  health_check {
    healthy_threshold   = 3
    interval            = 30
    #matcher             = "200,202"
    path                = "/index.html" # <- this is the path to apache html page defined on instances in private subnets
    unhealthy_threshold = 3
    timeout             = 5
  }
}

resource "aws_lb_target_group_attachment" "ec2_tg_attachment" {
  count            = length(aws_instance.linux)
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id        = element(aws_instance.linux.*.id, count.index)
  port             = 80

}

resource "aws_lb_listener" "front_end_listener" {
  load_balancer_arn = module.alb.this_lb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# Import existing key pair
resource "aws_key_pair" "kp" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Deploy instances in private subnets

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Deploy instances in private subnets
resource "aws_instance" "linux" {
  count = var.instances_per_private_subnet * length(module.vpc.private_subnets)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.kp.id

  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  vpc_security_group_ids = [module.private_ec2_security_group.security_group_id]
  
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    # install apache http server
    sudo yum install httpd -y 
    sudo systemctl enable httpd
    sudo systemctl start httpd

    # server ip address - see https://unix.stackexchange.com/questions/456853/get-and-use-server-ip-address-on-bash/456855
    IPADDR=$(ip -4 addr show eth0 | awk '/inet/ {print $2}' | sed 's#/.*##')
    
    echo "<html><body><div><p style="font-family:'Courier New'">apache http server<br/>private ip = $IPADDR</p></div></body></html>" > /var/www/html/index.html
    EOF
  
  tags = {
    Project = var.project_name
    Name    = "${var.project_name}-linux-${count.index}"
  }
}

# Deploy instances in public subnets

# Bootstrap Template File for configuring linux
data "template_file" "linux-vm-cloud-init" {
  template = file("linux_config.sh")
}

resource "aws_instance" "linux_pub" {
  count = var.instances_per_public_subnet * length(module.vpc.public_subnets)

  ami           = "ami-043097594a7df80ec"
  instance_type = var.instance_type
  key_name      = aws_key_pair.kp.id

  subnet_id              = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids = [module.public_ec2_security_group.security_group_id]
  
  user_data_base64 = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  
  tags = {
    Project = var.project_name
    Name    = "${var.project_name}-linux-pub-${count.index}"
  }
}
