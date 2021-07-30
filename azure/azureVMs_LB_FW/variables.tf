variable "subscriptionid" {
  type        = string
  description = "Azure Subscription ID"
  default     = "<AZURE SUBSCRIPTION ID>"                         # <----------------- EDIT ------------------
}

variable "location" {
  description = "The Azure Region in which all resources in this module should be created."
  type        = string
  default     = "west Europe"
}

variable "resourcegroup" {
  description = "The resourcegroup for this module."
  type        = string
  default     = "azureVMs_LB_FW"
}

variable "project_name" {
  description = "Name of the project. Used in resource names and tags."
  type        = string
  default     = "azureVMs_LB_FW"
}

variable "vnet_cidr_block" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets_per_vnet" {
  description = "Number of subnets. Maximum of 4."
  type        = number
  default     = 1                                               # <----------------- EDIT ------------------
}

variable "subnet_prefixes" {
  description = "Available cidr blocks for subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "subnet_names" {
  description = "subnet names"
  type        = list(string)
  default = [
    "subnet0",
    "subnet1",
    "subnet2",
    "subnet3"
  ]
}

variable "vm_instances_per_subnet" {
  description = "Number of vm instances in each subnet"
  type        = number
  default     = 2                                            # <----------------- EDIT ------------------
}

variable "user_name" {
  description = "Username for VMs"
  type        = string
  default     = "<USERNAME>"                                 # <----------------- EDIT ------------------
}

variable "public_key_path" {
  description = <<DESCRIPTION
    Path to the SSH public key to be used for authentication.
    Ensure this keypair is added to your local SSH agent so provisioners can
    connect.
    Example: ~/.ssh/terraform.pub
    DESCRIPTION
  type        = string
  default     = "<PATH>"                                     # <----------------- EDIT ------------------
}
