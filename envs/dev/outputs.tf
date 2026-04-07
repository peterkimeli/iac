# ──────────────────────────────────────────────
# Resource Group
# ──────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

# ──────────────────────────────────────────────
# ACR
# ──────────────────────────────────────────────
output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.acr_login_server
}

output "acr_name" {
  description = "ACR name"
  value       = module.acr.acr_name
}

# ──────────────────────────────────────────────
# AKS
# ──────────────────────────────────────────────
output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "kube_config" {
  description = "Kubeconfig for kubectl access"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

# ──────────────────────────────────────────────
# PostgreSQL
# ──────────────────────────────────────────────
output "postgres_server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.postgresql.server_fqdn
}

output "postgres_connection_string" {
  description = "JDBC connection string"
  value       = module.postgresql.connection_string
  sensitive   = true
}

# ──────────────────────────────────────────────
# Quick-start commands
# ──────────────────────────────────────────────
output "connect_to_aks" {
  description = "Command to connect to the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

# ──────────────────────────────────────────────
# Key Vault
# ──────────────────────────────────────────────
output "keyvault_name" {
  description = "Key Vault name"
  value       = module.keyvault.keyvault_name
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.keyvault_uri
}

output "eso_identity_client_id" {
  description = "Managed identity client ID — set this in gitops values.yaml secretStore.azure.clientId"
  value       = module.keyvault.eso_identity_client_id
}

output "gitops_values_patch" {
  description = "Copy-paste this into k8s-gitops/apps/ms-account-service/values.yaml"
  value       = <<-EOT
    secretStore:
      azure:
        keyvaultName: "${module.keyvault.keyvault_name}"
        tenantId:     "${var.tenant_id}"
        clientId:     "${module.keyvault.eso_identity_client_id}"
  EOT
}
