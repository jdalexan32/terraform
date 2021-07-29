variable "public_key_path" {
  description = <<DESCRIPTION
    Path to the SSH public key to be used for authentication.
    Ensure this keypair is added to your local SSH agent so provisioners can
    connect.
    Example: ~/.ssh/terraform.pub
    DESCRIPTION
  type        = string
  default     = "~/.ssh/terraform.pub"       #<---------------------change
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  type        = string
  default     = "terraform-provider-aws-outfield"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project. Used in resource names and tags."
  type        = string
  default     = "outfield"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets_per_vpc" {
  description = "Number of private subnets. Maximum of 4."
  type        = number
  default     = 2                            # <- can change but need at least two subnets in two different Availability Zones
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "public_subnets_per_vpc" {
  description = "Number of public subnets. Maximum of 4."
  type        = number
  default     = 2                            # <- can change but need at least one public subnet in each of the Availability Zones used by your targets
                                             # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-application-load-balancer.html
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24"
  ]
}

variable "instances_per_private_subnet" {
  description = "Number of EC2 instances in each private subnet"
  type        = number
  default     = 2
}

variable "instances_per_public_subnet" {
  description = "Number of EC2 instances in each public subnet"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Type of EC2 instance to use."
  type        = string
  default     = "t2.micro"
}
