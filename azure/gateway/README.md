# gateway #  
Terraform code to build a vpn gateway in Azure as illustrated below.

![image](https://user-images.githubusercontent.com/15988353/126059122-289c382f-b260-492f-9d55-3083dc33ee73.png)


### Prerequisites ###

* Terraform installed, see https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started  
* An Azure subscription. Create a free account at https://azure.microsoft.com/en-us/free/
* Azure CLI Tool installed, see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli  

### Configurations Required ###
* Edit the ```variables.tf``` file - update "*subscriptionid*" variable with your Azure Azure Subscription ID
* Edit the ```vnetgateway-vpn.tf``` file - enter public certificate data for your vpn client
* Edit the ```gateway-nginx.tf``` file - enter username for VM and the path to your public key

- - -  
## Deploy Infrastructure ##

1. Clone or download files in this repository
2. Edit the ```variables.tf``` file (see above Configurations Required)
3. ```terraform init```
4. ```terraform plan```
5. ```terraform apply```

## Remove Infrastructure ##
1. ```terraform destroy```
