terraform {

  # Pins the version of Terraform to a specific version
  # If this block is in a Child Module, then use a 'minimum' version only
  required_version = "=1.2.0"

  # Pins the version of your providers to a specific version
  # You should specify all providers used by the Root Module, as well as all providers used by any Child Modules
  # If this block is in a Child Module, then use 'minimum' versions only
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.7.0"
      configuration_aliases = [ azurerm.second ]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.22.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.5.1"
    }
  }

  # Backend values must be hard-coded, they can not reference Terraform variables, locals, or data sources
  # You can only have one backend block per Root Module
  backend "azurerm" {
    # Example - Service Principal and Secret
    # tenant_id          = "value"  # think about extracting this from code and using the env var: ARM_TENANT_ID
    # client_id          = "value"  # think about extracting this from code and using the env var: ARM_CLIENT_ID
    # client_secret      = "value"  # think about extracting this from code and using the env var: ARM_CLIENT_SECRET
    # subscription_id    = "value"  # think about extracting this from code and using the env var: ARM_SUBSCRIPTION_ID
    resource_group_name  = "value"  # think about extracting this from code and using Partial Configuration, see below
    storage_account_name = "value"  # think about extracting this from code and using Partial Configuration, see below
    container_name       = "value"  # think about extracting this from code and using Partial Configuration, see below
    key                  = "value"  # think about extracting this from code and using Partial Configuration, see below
  }

  # Partial Configuration Option 1. Specify backend settings in an external file
    # Still include an empty backend block:  backend "azurerm" {}
    # terraform init -backend-config=path/to/backend.hcl
    # The contents of backend.hcl are just key/value pairs only

  # Partial Configuration Option 2. Specify backend settings on the command-line
    # Still include an empty backend block:  backend "azurerm" {}
    # terraform init -backend-config="resource_group_name=value" -backend-config="storage_account_name=value"

  # Note: Command-line options take priority over the options defined in the terraform backend block
  # Note: Command-line options are processed in order, so the last option on the command-line wins
}

# Provider configuration blocks belong in the Root Module only, and do not belong in Child Modules
provider "azurerm" {
  # Example - Service Principal with Secret
  # tenant_id       = "value"  # think about extracting this from code and using the env var: ARM_TENANT_ID
  # client_id       = "value"  # think about extracting this from code and using the env var: ARM_CLIENT_ID
  # client_secret   = "value"  # think about extracting this from code and using the env var: ARM_CLIENT_SECRET
  # subscription_id = "value"  # think about extracting this from code and using the env var: ARM_SUBSCRIPTION_ID
  
  features {}  # the features block is always required, even if its empty
}

provider "azurerm" {
  alias = "second"

  features {}
}
