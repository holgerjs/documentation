## Enabling 'Soft Delete' for Blobs in Azure Storage Accounts using Terraform

### What is Soft Delete?

> Blob soft delete protects an individual blob, snapshot, or version from accidental deletes or overwrites by maintaining the deleted data in the system for a specified period of time. During the retention period, you can restore a soft-deleted object to its state at the time it was deleted. After the retention period has expired, the object is permanently deleted.
<br>&mdash; <cite>[Azure Documentation - Soft delete for blobs](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview) </cite>[1]

Besides enabling Blob soft delete, Microsoft recommends enabling further data protection features:
- [Container soft delete](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-enable), to restore a container that has been deleted [2].
- [Blob versioning](https://learn.microsoft.com/en-us/azure/storage/blobs/versioning-enable), to automatically maintain previous versions of a blob [3].

### How can I configure Blob Soft Delete through Terraform?

The Azure Portal has the settings under `Data Protection -> Enable soft delete for blobs`.

![Azure Portal Blob Soft Delete Settings]()

However, the [Azure Storage Account REST API](https://learn.microsoft.com/en-us/rest/api/storageservices/set-blob-service-properties?tabs=azure-ad) has the same configuration as `DeleteRetentionPolicy` [4] and terraform uses a similar wording with `delete_retention_policy` with their [azurerm_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) resource [5].

The setting can be configured as part of the `blob_properties` block of the `azurerm_storage_account` resource. For example, if we wanted to enable soft delete with a retention time of 5 days, the setting could be:

```terraform
  blob_properties {
    delete_retention_policy {
      days = 5
    }
  }
```

The full configuration with a resource group and storage account could be like this:

```terraform
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_id" "deployment_id" {
  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  location = "westeurope"
  name     = "rg-${lower(random_id.deployment_id.hex)}"
  tags = {
    environment = "test"
  }
}

resource "azurerm_storage_account" "storage_acct" {
  name = "stg${lower(random_id.deployment_id.hex)}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true
  
  blob_properties {
    last_access_time_enabled = true
    delete_retention_policy {
      days = 5
    }
  }

  tags = {
    environment = "test"
  }
}

output "storage_account_blob_uri" {
  value = azurerm_storage_account.storage_acct.primary_blob_endpoint
  description = "Primary Blob Endpoint"
}
```

Above configuration would create a resource group and storage account with a random number as suffix. Furthermore, the primary blob endpoint is added as output to the console.

Once applied, the setting should be reflected in the Azure Portal as well.

![Azure Portal - Soft Delete]()

### References

| # | Title | URL | Accessed-On |
| --- | --- | --- | --- |
| 1 | Soft delete for blobs | https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview | 2023-01-26 |
| 2 | Enable and manage soft delete for containers | https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-enable?tabs=azure-portal | 2023-01-26 |
| 3 | Enable and manage blob versioning | https://learn.microsoft.com/en-us/azure/storage/blobs/versioning-enable?tabs=portal | 2023-01-26 |
| 4 | Azure REST API - Set Blob Service Properties | https://learn.microsoft.com/en-us/rest/api/storageservices/set-blob-service-properties?tabs=azure-ad | 2023-01-26 |
| 5 | azurerm_storage_account | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account | 2023-01-26 |