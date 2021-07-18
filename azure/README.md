# gateway #

### Prerequisites ###

* Terraform installed, see https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started  
- - -  
## Azure ##

The Azure terraform code creates a resource group, VNet, subnets, security groups, and Linux VMs in the various subnets. The number of subnets and VM's per subnet is configurable.

### Azure Prerequisites ###
* An Azure subscription. Create a free account at https://azure.microsoft.com/en-us/free/
* Azure CLI Tool installed, see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
