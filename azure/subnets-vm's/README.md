# Multiple Subnets and VM's #  
Terraform code to build a simple infrastructure consisting of multiple Subnets, Security Groups and Linux VM's. The number of Subnets and VM's-per-subnet is configurable.  


![project1](https://user-images.githubusercontent.com/15988353/126063627-daaca52c-8c12-46d5-b6fa-03572f08b26f.png)


### Prerequisites ###

* Terraform installed, see https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started  
* An Azure subscription. Create a free account at https://azure.microsoft.com/en-us/free/
* Azure CLI Tool installed, see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli  
* SSH keys for authentication to VM's

### Configurations Required ###
* Edit the ```variables.tf``` file  
 1. update "*subscriptionid*" variable with your Azure Azure Subscription ID
 2. Edit "*user_name*"
 3. Edit "*public_key_path*"
* Edit ```linux_config.sh``` script - update script with your username 

- - -  
## Deploy Infrastructure ##

1. Clone or download files in this repository
2. Edit the ```variables.tf``` file (see above Configurations Required)
3. ```terraform init```
4. ```terraform plan```
5. ```terraform apply```

## Remove Infrastructure ##
1. ```terraform destroy```
