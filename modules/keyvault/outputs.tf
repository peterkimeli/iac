output "keyvault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "URI of the Key Vault (used in ClusterSecretStore)"
  value       = azurerm_key_vault.main.vault_uri
}

output "eso_identity_client_id" {
  description = "Client ID of the managed identity — add this to values.yaml secretStore.azure.clientId"
  value       = azurerm_user_assigned_identity.eso.client_id
}

output "eso_identity_id" {
  description = "Full resource ID of the managed identity"
  value       = azurerm_user_assigned_identity.eso.id
}
