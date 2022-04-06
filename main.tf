# -------------------------------------------------------------------------
# Pierre Mathieu
# # Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
       key_vault {
      purge_soft_delete_on_destroy = false
    }
  }


  subscription_id   = var.subscription_id
  tenant_id         = var.tenant_id
  client_id         = var.client_id
  client_secret     = var.client_secret
}

data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "resource-grp" {
  name = "${var.project}-${var.environment}-func-resource-group"
  location = var.location
  tags = {
    "environment" = "dev"
    "owner"       = "poc-owner"
  }
}

# Create internal Storage Account, Storage Container.
resource "azurerm_storage_account" "int-storage-acct" {
  name                     = "internalstorageacct"
  resource_group_name = azurerm_resource_group.resource-grp.name
  location            = azurerm_resource_group.resource-grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "int-storage-container" {
  name                  = "internal-storage-container"
  storage_account_name  = azurerm_storage_account.int-storage-acct.name
  container_access_type = "private"
}

# Create external Storage Account, Storage Container.
resource "azurerm_storage_account" "ext-storage-acct" {
  name                     = "externalstorageacct"
  resource_group_name = azurerm_resource_group.resource-grp.name
  location            = azurerm_resource_group.resource-grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ext-storage-container" {
  name                  = "external-storage-container"
  storage_account_name  = azurerm_storage_account.ext-storage-acct.name
  container_access_type = "private"
}


#Create share file account and Share
resource "azurerm_storage_account" "share-storage-acct" {
  name                     = "sharestorageacct"
  resource_group_name = azurerm_resource_group.resource-grp.name
  location            = azurerm_resource_group.resource-grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#Quota Must be greater than 0, and less than or equal to 5 TB (5120 GB).
resource "azurerm_storage_share" "storageshare" {
  name = "file-share"
  storage_account_name = azurerm_storage_account.share-storage-acct.name

  quota = 100
}


#Create directory for the file share
resource "azurerm_storage_share_directory" "sharedir" {
  name                 = "sharedirectory"
  share_name           = azurerm_storage_share.storageshare.name
  storage_account_name = azurerm_storage_account.share-storage-acct.name
}

resource "azurerm_storage_account" "func_storage_account" {
  name = "functstorageacct"
  resource_group_name =  azurerm_resource_group.resource-grp.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource-grp.name
  location            = var.location
  kind                = "FunctionApp"
  reserved = true 
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}


resource "azurerm_function_app" "function_app" {
  name                       = "${var.project}${var.environment}-function-app"
  resource_group_name        = azurerm_resource_group.resource-grp.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "",
    "FUNCTIONS_WORKER_RUNTIME" = "python",
    "APP_TOKEN_VALUE" = "",
    "FILE_ENCRYPTION_KEY" = "",
    "AZURE_STORAGE_CONNECTION_STRING" = "", 
    "AZURE_INTERNAL_STORAGE_CONNECTION_STRING"  = "",
    "SERVICE_BUS_CONNECTION_STR" = "",
    "SERVICE_BUS_QUEUE_NAME" = ""
    }
  os_type = "linux"
  site_config {
    linux_fx_version          = "python|3.9"
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key
  version                    = "~3"

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}