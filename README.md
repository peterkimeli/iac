# Infrastructure as Code — ms-account-service

Terraform modules and Kubernetes manifests for deploying the **ms-account-service** to Azure Kubernetes Service (AKS).

## 📁 Structure

```
iac/
├── modules/               # Reusable Terraform modules
│   ├── networking/         # VNet, subnets, NSG, Private DNS
│   ├── acr/                # Azure Container Registry
│   ├── aks/                # AKS cluster + Log Analytics
│   └── postgresql/         # PostgreSQL Flexible Server
├── envs/                   # Per-environment configurations
│   └── dev/                # Dev environment
│       ├── main.tf         # Module composition
│       ├── variables.tf    # Input variables
│       ├── terraform.tfvars # Dev values (fill in IDs)
│       ├── outputs.tf      # Useful outputs
│       ├── providers.tf    # Provider config
│       └── backend.tf      # Remote state (commented out)
└── k8s/                    # Kubernetes manifests
    └── dev/
        ├── namespace.yaml
        ├── configmap.yaml
        ├── secret.yaml       # Update with real DB creds
        ├── deployment.yaml   # Update ACR image URL
        ├── service.yaml
        ├── ingress.yaml
        ├── serviceaccount.yaml
        └── hpa.yaml
```

## 🚀 Quick Start (Dev)

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- An Azure subscription

### 1. Authenticate with Azure
```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Configure variables
Edit `envs/dev/terraform.tfvars` and fill in:
- `subscription_id`
- `tenant_id`

### 3. Deploy infrastructure
```bash
cd envs/dev

terraform init
terraform plan \
  -var="postgres_admin_username=pgadmin" \
  -var="postgres_admin_password=YourStr0ngP@ss!"

terraform apply \
  -var="postgres_admin_username=pgadmin" \
  -var="postgres_admin_password=YourStr0ngP@ss!"
```

### 4. Connect to AKS
```bash
az aks get-credentials \
  --resource-group rg-accountsvc-dev \
  --name aks-accountsvc-dev
```

### 5. Push image to ACR
```bash
# Get ACR login server from terraform output
ACR_SERVER=$(terraform output -raw acr_login_server)

az acr login --name $(terraform output -raw acr_name)

docker tag kimeli/ms-account-service:1.0.0 $ACR_SERVER/ms-account-service:1.0.0
docker push $ACR_SERVER/ms-account-service:1.0.0
```

### 6. Deploy to Kubernetes
```bash
# Update k8s/dev/deployment.yaml with ACR_SERVER
# Update k8s/dev/secret.yaml with PostgreSQL connection details from:
#   terraform output -raw postgres_connection_string

kubectl apply -f ../../k8s/dev/
```

## 🌍 Adding New Environments

To add `staging` or `prod`:

1. Copy `envs/dev/` → `envs/staging/`
2. Update `terraform.tfvars` with environment-specific values (larger VMs, more nodes, etc.)
3. Copy `k8s/dev/` → `k8s/staging/` and adjust replicas, resources, ingress host
4. Run `terraform init && terraform apply` from the new env directory

## 🔐 Security Notes

- PostgreSQL credentials should be passed via CLI vars or `TF_VAR_*` env vars — **never** commit passwords to git
- K8s secrets should be managed via [External Secrets Operator](https://external-secrets.io/) or [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) in production
- ACR uses managed identity (AcrPull role) — no image pull secrets needed
- AKS uses Azure AD RBAC for cluster access

## 📊 What Gets Created (Dev)

| Resource | Name | SKU/Size |
|----------|------|----------|
| Resource Group | rg-accountsvc-dev | — |
| Virtual Network | vnet-accountsvc-dev | 10.0.0.0/16 |
| AKS Cluster | aks-accountsvc-dev | 1x Standard_B2s |
| Container Registry | acraccountevcdev | Basic |
| PostgreSQL | psql-accountsvc-dev | B_Standard_B1ms |
| Log Analytics | log-accountsvc-dev | PerGB2018 |
