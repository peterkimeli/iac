resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_vm_size
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = var.os_disk_size_gb
    max_pods            = 50
    type                = "VirtualMachineScaleSets"
    zones               = var.availability_zones

    # Autoscaling
    enable_auto_scaling = true
    node_count          = var.system_node_count
    min_count           = var.system_node_min_count
    max_count           = var.system_node_max_count

    # Reserve system pool for system workloads only
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
    max_graceful_termination_sec = 600
  }

  tags = var.tags
}

# App (user) node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  count                 = var.enable_app_node_pool ? 1 : 0
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.app_node_vm_size
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = var.os_disk_size_gb
  zones                 = var.availability_zones
  max_pods              = 30
  mode                  = "User"

  # Autoscaling
  enable_auto_scaling   = true
  node_count            = var.app_node_count
  min_count             = var.app_node_min_count
  max_count             = var.app_node_max_count

  node_labels = {
    "workload" = "app"
  }

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}

# Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                            = var.enable_acr_integration ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
