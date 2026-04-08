# ──────────────────────────────────────────────────────────────────────────────
# Azure Key Vault + Workload Identity for External Secrets Operator
#
# What this module provisions:
#   1. Key Vault (RBAC-authorized)
#   2. User-assigned Managed Identity for ESO
#   3. "Key Vault Secrets User" role assignment on the vault
#   4. Federated Identity Credential — links K8s SA to the managed identity
#      so ESO can authenticate without any stored credentials
#   5. Key Vault Secrets — seeds the PostgreSQL connection values
#      so Terraform is the single source of truth for sensitive config
#
# Flow:
#   Terraform writes secrets → Key Vault
#   ESO (using Workload Identity) reads secrets → K8s Secret
#   Reloader detects K8s Secret change → rolling restart
# ──────────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

resource "random_id" "kv_suffix" {
  byte_length = 3
}

locals {
  keyvault_name = "kv-${var.project}-${var.environment}-${random_id.kv_suffix.hex}"
  identity_name = "mi-${var.project}-eso-${var.environment}"
}

# ── 1. Key Vault ──────────────────────────────────────────────────────────────
resource "azurerm_key_vault" "main" {
  name                = local.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # RBAC authorization — role assignments control access (modern approach)
  enable_rbac_authorization = true

  # Protect against accidental deletion in prod; fine to disable for dev
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"   # tighten to "Deny" + ip_rules when you have a fixed egress IP
  }

  tags = var.tags
}

# ── 2. User-assigned Managed Identity for ESO ─────────────────────────────────
resource "azurerm_user_assigned_identity" "eso" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ── 3. Grant the managed identity read access to Key Vault secrets ────────────
# "Key Vault Secrets User" = Get + List secrets (read-only, principle of least privilege)
resource "azurerm_role_assignment" "eso_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.eso.principal_id
}

# Also grant Terraform's own identity "Key Vault Secrets Officer" so it can write secrets below
resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── 4. Federated Identity Credential ─────────────────────────────────────────
# This is the Workload Identity bridge:
# When the K8s pod (using ServiceAccount `app_service_account_name`) requests
# an Azure token, AKS presents a signed JWT to Azure AD. Azure AD validates it
# against this federated credential and returns a token for the managed identity.
# No secrets are stored anywhere in the cluster.
resource "azurerm_federated_identity_credential" "eso" {
  name                = "eso-keyvault-federated"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.eso.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:${var.app_namespace}:${var.app_service_account_name}"
}

# ── 5. Seed secrets — Terraform is the source of truth ───────────────────────
# These depend on the role assignment existing first (RBAC propagation can take ~30s)
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.terraform_kv_secrets_officer]
  create_duration = "30s"
}

resource "azurerm_key_vault_secret" "db_url" {
  name         = "ms-account-service-db-url"
  value        = "jdbc:postgresql://${var.db_server_fqdn}:5432/${var.db_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
  depends_on   = [time_sleep.wait_for_rbac]
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "ms-account-service-db-username"
  value        = var.db_username
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
  depends_on   = [time_sleep.wait_for_rbac]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "ms-account-service-db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
  depends_on   = [time_sleep.wait_for_rbac]
}

resource "azurerm_key_vault_secret" "db_pool_size" {
  name         = "ms-account-service-db-pool-size"
  value        = var.db_pool_size
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
  depends_on   = [time_sleep.wait_for_rbac]
}
