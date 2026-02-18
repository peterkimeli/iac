# ──────────────────────────────────────────────
# Fill in your Azure subscription and tenant IDs
# ──────────────────────────────────────────────
subscription_id = "50f529c1-ce1a-41ba-85ae-a60f5d0492bf"
tenant_id       = "db56775d-ae7e-493b-ac83-5ff500fc2fb1"

# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
project     = "accountsvc"
environment = "dev"
location    = "southafricanorth"

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
vnet_address_space   = ["10.0.0.0/16"]
aks_subnet_cidr      = "10.0.0.0/20"
postgres_subnet_cidr = "10.0.16.0/24"

# ──────────────────────────────────────────────
# AKS
# ──────────────────────────────────────────────
kubernetes_version    = "1.34"
system_node_count     = 1
system_node_vm_size   = "Standard_B2s_v2"
system_node_min_count = 1
system_node_max_count = 3

# App (user) node pool
app_node_vm_size  = "Standard_B2s_v2"
app_node_count    = 1
app_node_min_count = 1
app_node_max_count = 5

# ──────────────────────────────────────────────
# PostgreSQL
# ──────────────────────────────────────────────
postgres_sku        = "B_Standard_B1ms"
postgres_storage_mb = 32768

# Pass these via CLI or env vars to avoid storing secrets in tfvars:
#   terraform plan -var="postgres_admin_username=pgadmin" -var="postgres_admin_password=YourStr0ngP@ss!"
# Or export:
#   export TF_VAR_postgres_admin_username="pgadmin"
#   export TF_VAR_postgres_admin_password="YourStr0ngP@ss!"
