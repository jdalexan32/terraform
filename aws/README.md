# Terraform for AWS #  
The AWS terraform code creates a VPC, load balancer, public and private subnets in two availability zones, security groups, Linux VMs in the various subnets, routing tables and an internet gateway. The number of subnets and VM's per subnet is configurable.  

## Terraform Prerequisites ##

* Terraform installed, see https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started  

## AWS Prerequisites ##
* An AWS subscription. Create a free account at https://aws.amazon.com/free/
* AWS CLI Tool installed, see https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
* Your AWS credentials. You can create a new Access Key on this page - https://console.aws.amazon.com/iam/home?#/security_credentials  

## AWS Configurations ##  
#### Edit the ```variables.tf``` file ####
* Update "*public_key_path*" variable with your public key path
* Change any other variables per need  

## Deploy Infrastructure ##

1. Clone or download files in this repository
2. Edit the ```variables.tf``` file (see above for specific Azure and AWS configurations)
3. ```terraform init```
4. ```terraform plan```
5. ```terraform apply```

## Remove Infrastructure ##
1. ```terraform destroy```
