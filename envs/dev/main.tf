locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "ms-account-service"
  }
}

# ──────────────────────────────────────────────
# Resource Group
# ──────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# Brief pause to let the resource group propagate across Azure
resource "time_sleep" "wait_for_rg" {
  depends_on      = [azurerm_resource_group.main]
  create_duration = "30s"
}

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  vnet_address_space  = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  postgres_subnet_cidr = var.postgres_subnet_cidr
  tags                = local.tags

  depends_on = [time_sleep.wait_for_rg]
}

# ──────────────────────────────────────────────
# Azure Container Registry
# ──────────────────────────────────────────────
module "acr" {
  source = "../../modules/acr"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  acr_sku             = "Basic"
  tags                = local.tags

  depends_on = [time_sleep.wait_for_rg]
}

# ──────────────────────────────────────────────
# AKS Cluster
# ──────────────────────────────────────────────
module "aks" {
  source = "../../modules/aks"

  project              = var.project
  environment          = var.environment
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  kubernetes_version   = var.kubernetes_version
  system_node_count    = var.system_node_count
  system_node_vm_size  = var.system_node_vm_size
  system_node_min_count = var.system_node_min_count
  system_node_max_count = var.system_node_max_count
  aks_subnet_id        = module.networking.aks_subnet_id
  tenant_id            = var.tenant_id
  acr_id               = module.acr.acr_id
  enable_acr_integration = true
  enable_app_node_pool = true
  app_node_vm_size     = var.app_node_vm_size
  app_node_count       = var.app_node_count
  app_node_min_count   = var.app_node_min_count
  app_node_max_count   = var.app_node_max_count
  log_retention_days   = 30
  tags                 = local.tags

  depends_on = [module.networking]
}

# ──────────────────────────────────────────────
# PostgreSQL Flexible Server
# ──────────────────────────────────────────────
module "postgresql" {
  source = "../../modules/postgresql"

  project              = var.project
  environment          = var.environment
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  admin_username       = var.postgres_admin_username
  admin_password       = var.postgres_admin_password
  sku_name             = var.postgres_sku
  storage_mb           = var.postgres_storage_mb
  postgres_subnet_id   = module.networking.postgres_subnet_id
  postgres_dns_zone_id = module.networking.postgres_dns_zone_id
  database_name        = "fintech_accounts"
  tags                 = local.tags

  depends_on = [module.networking]
}

# ──────────────────────────────────────────────
# Key Vault + Workload Identity (ESO)
# ──────────────────────────────────────────────
module "keyvault" {
  source = "../../modules/keyvault"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id

  # Workload Identity — from AKS OIDC issuer
  aks_oidc_issuer_url      = module.aks.oidc_issuer_url
  app_namespace            = var.app_namespace
  app_service_account_name = var.app_service_account_name

  # Seed PostgreSQL secrets into Key Vault
  db_server_fqdn = module.postgresql.server_fqdn
  db_name        = "fintech_accounts"
  db_username    = var.postgres_admin_username
  db_password    = var.postgres_admin_password
  db_pool_size   = var.keyvault_db_pool_size

  tags = local.tags

  depends_on = [module.aks, module.postgresql]
}
