resource "random_integer" "acr_suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_container_registry" "main" {
  name                = replace("acr${var.project}${var.environment}${random_integer.acr_suffix.result}", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = var.tags
}
