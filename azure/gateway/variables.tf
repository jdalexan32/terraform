variable "subscriptionid" {
  type        = string
  description = "Azure Subscription ID"
  default = "<ENTER SUBSCRIPTION ID HERE>"        # <----------------- EDIT ------------------
}

variable "location" {
  description = "The Azure Region in which all resources in this module should be created."
  default = "west Europe"
}

variable "prefix" {
  description = "The prefix which should be used for all resources in this module"
}
