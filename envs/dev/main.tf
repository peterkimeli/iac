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
  aks_subnet_id        = module.networking.aks_subnet_id
  tenant_id            = var.tenant_id
  acr_id               = module.acr.acr_id
  enable_app_node_pool = false
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
