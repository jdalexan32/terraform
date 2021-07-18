# Azure Firewall, Loadbalancer, Subnets and VM's #  
Terraform code to build an infrastructure consisting of a Azure Firewall, Loadbalancer, multiple Subnets, Security Groups and Linux VM's. The number of Subnets and VM's-per-subnet is configurable.  

![project2](https://user-images.githubusercontent.com/15988353/126065196-f63b55ac-a1a3-4828-bea3-9f07438060be.png)


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
2. Edit the ```variables.tf``` file and ```linux_config.sh``` script (see above Configurations Required)
3. ```terraform init```
4. ```terraform plan```
5. ```terraform apply```

## Remove Infrastructure ##
1. ```terraform destroy```
