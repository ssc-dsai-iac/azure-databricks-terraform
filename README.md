# Azure Databricks Terraform Module

Terraform Module to create an Azure storage account with a set of containers.

To defines the kind of account, set the argument to `account_kind = "StorageV2"`. 
Account kind defaults to `StorageV2`. If you want to change this value to other storage accounts kind, then this module automatically computes the appropriate values for `account_tier`, `account_replication_type`. The valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. `static_website` can only be set when the account_kind is set to `StorageV2`.

## Module Usage

```hcl
# Azure Provider configuration
provider "azurerm" {
  features {}
}

module "storage-account" {
  source  = "github.com/ssc-dsai-iac/azure-storage-account-terraform"

  # By default, this module will not create a resource group
  # provide a name to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  resource_group_name	  = "${var.prefix}-${var.group}-${var.user_defined}-${var.env}-rg"
  location              = var.location
  storage_account_name	= "${var.prefix}csa${var.group}${var.user_defined}dls1"

  # Container lists to create
  containers_list = [
    "Container1",
    "Container2",
    "Container3",
  ]

  # For network rules, the default action is set to "Deny", 
  #therefore to access the storage account one of either 
  #`virtual_network_ip_rules` or `virtual_network_subnet_ids` must be specified.
  virtual_network_subnet_ids = [azurerm_subnet.this.id]
  virtual_network_ip_rules = ["127.0.0.1"]

  tags = {
    env        = var.env
    costcenter = var.costcenter
    ssn        = var.ssn
    subowner   = var.subowner
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| azurerm | >= 2.82.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.82.0 |

## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`create_resource_group`|Whether to create resource group and use it for all networking resources|bool| `false`
`resource_group_name`|The name of the resource group in which resources are created|string|`"rg-demo"`
`location`|The name of the storage account to be created|string| `"Canada Central"`
`storage_account_name`|The name of the resource group in which resources are created|string|`""`
`account_kind`|General-purpose v2 accounts: Basic storage account type for blobs, files, queues, and tables.|string|`"StorageV2"`
`skuname`|The SKUs supported by Microsoft Azure Storage. Valid options are Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS, Standard_RAGRS, Standard_RAGZRS, Standard_ZRS|string|`Standard_LRS`
`access_tier`|Defines the access tier for BlobStorage and StorageV2 accounts. Valid options are Hot and Cool.|string|`"Hot"`
`virtual_network_subnet_ids`|List of subnets to permit access to the storage account|list(string)|`[]`
`virtual_network_ip_rules`|List of IP rules to permit access to the storage account|list(string)|`[]`
`containers_list`| List of container|list(string)|`[]`
`identity_ids`| Specifies a list of user managed identity ids to be assigned. This is required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`|list(string)|`null`
`Tags`|A map of tags to add to all resources|map|`{}`

## Outputs

Name | Description
---- | -----------
`resource_group_name`|The name of the resource group in which resources are created
`resource_group_id`|The id of the resource group in which resources are created
`resource_group_location`|The location of the resource group in which resources are created
`storage_account_id`|The ID of the storage account
`sorage_account_name`|The name of the storage account
`storage_account_primary_location`|The primary location of the storage account
`storage_account_primary_web_endpoint`|The endpoint URL for web storage in the primary location
`storage_account_primary_web_host`|The hostname with port if applicable for web storage in the primary location
`storage_primary_connection_string`|The primary connection string for the storage account
`storage_primary_access_key`|The primary access key for the storage account
`storage_secondary_access_key`|The secondary access key for the storage account
`containers`|Map of containers