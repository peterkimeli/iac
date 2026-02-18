variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
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

variable "enable_app_node_pool" {
  description = "Whether to create a separate app node pool"
  type        = bool
  default     = false
}

variable "app_node_vm_size" {
  description = "VM size for app nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "app_node_count" {
  description = "Initial number of app nodes"
  type        = number
  default     = 1
}

variable "app_node_min_count" {
  description = "Minimum number of app nodes (autoscaler)"
  type        = number
  default     = 1
}

variable "app_node_max_count" {
  description = "Maximum number of app nodes (autoscaler)"
  type        = number
  default     = 3
}

variable "enable_auto_scaling" {
  description = "Enable node autoscaler"
  type        = bool
  default     = false
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "availability_zones" {
  description = "Availability zones for nodes"
  type        = list(string)
  default     = []
}

variable "aks_subnet_id" {
  description = "ID of the subnet for AKS"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.64.0/19"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.0.64.10"
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "acr_id" {
  description = "ID of the ACR to grant pull access"
  type        = string
  default     = ""
}

variable "enable_acr_integration" {
  description = "Whether to grant AKS pull access to ACR"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
