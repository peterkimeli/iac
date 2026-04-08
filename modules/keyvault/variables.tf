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
  description = "Resource group to deploy into"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

# ── Workload Identity — links ESO's K8s ServiceAccount to this managed identity ──
variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL from the AKS cluster (for federated identity)"
  type        = string
}

variable "app_namespace" {
  description = "K8s namespace the app ServiceAccount lives in"
  type        = string
  default     = "accountsvc-dev"
}

variable "app_service_account_name" {
  description = "K8s ServiceAccount name that ESO uses"
  type        = string
  default     = "ms-account-service"
}

# ── Secrets to seed into Key Vault ───────────────────────────────────────────
variable "db_server_fqdn" {
  description = "PostgreSQL server FQDN"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "fintech_accounts"
}

variable "db_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "db_pool_size" {
  description = "HikariCP max pool size stored as a secret"
  type        = string
  default     = "10"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
