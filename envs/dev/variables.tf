# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "accountsvc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "CIDR for the AKS subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "postgres_subnet_cidr" {
  description = "CIDR for the PostgreSQL subnet"
  type        = string
  default     = "10.0.16.0/24"
}

# ──────────────────────────────────────────────
# AKS
# ──────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = "Number of system nodes"
  type        = number
  default     = 1
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_B2s"
}

# ──────────────────────────────────────────────
# PostgreSQL
# ──────────────────────────────────────────────
variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "postgres_sku" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

# ──────────────────────────────────────────────
# AKS – Autoscaling
# ──────────────────────────────────────────────
variable "system_node_min_count" {
  description = "Minimum system nodes (autoscaler)"
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum system nodes (autoscaler)"
  type        = number
  default     = 3
}

variable "app_node_vm_size" {
  description = "VM size for app/user nodes"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "app_node_count" {
  description = "Initial number of app nodes"
  type        = number
  default     = 1
}

variable "app_node_min_count" {
  description = "Minimum app nodes (autoscaler)"
  type        = number
  default     = 1
}

variable "app_node_max_count" {
  description = "Maximum app nodes (autoscaler)"
  type        = number
  default     = 5
}
