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
│       ├── terraform.tfvars # Dev values
│       ├── outputs.tf      # Useful outputs
│       ├── providers.tf    # Provider config
│       └── backend.tf      # Remote state (Azure Blob)
└── k8s/                    # Kubernetes manifests
    └── dev/
        ├── namespace.yaml
        ├── configmap.yaml
        ├── secret.yaml
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        ├── serviceaccount.yaml
        └── hpa.yaml
```

## 🚀 Quick Start (Dev)

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- An Azure subscription

### 1. Authenticate with Azure
```bash
az login --tenant db56775d-ae7e-493b-ac83-5ff500fc2fb1
az account set --subscription "50f529c1-ce1a-41ba-85ae-a60f5d0492bf"
```

### 2. Deploy infrastructure
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

### 3. Connect to AKS
```bash
az aks get-credentials --resource-group rg-accountsvc-dev --name aks-accountsvc-dev
```

### 4. Push image to ACR
```bash
ACR_SERVER=$(terraform -chdir=envs/dev output -raw acr_login_server)
az acr login --name $(terraform -chdir=envs/dev output -raw acr_name)
docker tag kimeli/ms-account-service:1.0.0 $ACR_SERVER/ms-account-service:1.0.0
docker push $ACR_SERVER/ms-account-service:1.0.0
```

### 5. Deploy to Kubernetes
```bash
kubectl apply -f k8s/dev/
```

## 📊 What Gets Created (Dev)

| Resource | Name | Details |
|----------|------|---------|
| Resource Group | `rg-accountsvc-dev` | South Africa North |
| Virtual Network | `vnet-accountsvc-dev` | `10.0.0.0/16` |
| AKS Cluster | `aks-accountsvc-dev` | K8s 1.34, 2 node pools |
| System Node Pool | `system` | Standard_B2s_v2, autoscale 1→3 |
| App Node Pool | `app` | Standard_B2s_v2, autoscale 1→5 |
| Container Registry | `acraccountsvcdev*` | Basic SKU |
| PostgreSQL | `psql-accountsvc-dev` | B_Standard_B1ms, 32 GB |
| Log Analytics | `log-accountsvc-dev` | PerGB2018 |

---

## 🔧 Troubleshooting — Commands to Run

### Azure Authentication

```bash
# Login to Azure
az login --tenant db56775d-ae7e-493b-ac83-5ff500fc2fb1

# Check current subscription
az account show --output table

# Switch subscription
az account set --subscription "50f529c1-ce1a-41ba-85ae-a60f5d0492bf"

# Check who you're logged in as
az ad signed-in-user show --query userPrincipalName -o tsv
```

### Resource Group Issues

```bash
# Check if the resource group exists
az group exists --name rg-accountsvc-dev

# List resources in the resource group
az resource list --resource-group rg-accountsvc-dev --output table

# Delete the resource group (full cleanup)
az group delete --name rg-accountsvc-dev --yes --no-wait

# Wait until deletion completes
while [ "$(az group exists --name rg-accountsvc-dev)" = "true" ]; do
  echo "Waiting for RG deletion..." && sleep 10
done && echo "Deleted"
```

### Terraform State Issues

```bash
# List state file in Azure Blob
az storage blob list \
  --account-name stfinsenseterraform \
  --container-name tfstate \
  --auth-mode key \
  --account-key "$(az storage account keys list --resource-group rg-terraform-state --account-name stfinsenseterraform --query '[0].value' -o tsv)" \
  --output table

# Delete state file (for a full clean re-apply)
az storage blob delete \
  --account-name stfinsenseterraform \
  --container-name tfstate \
  --name "ms-account-service/dev.tfstate" \
  --auth-mode key \
  --account-key "$(az storage account keys list --resource-group rg-terraform-state --account-name stfinsenseterraform --query '[0].value' -o tsv)"

# List Terraform state resources locally
cd envs/dev && terraform state list

# Remove a specific resource from state (without destroying it)
terraform state rm 'module.aks.azurerm_role_assignment.aks_acr_pull[0]'

# Import an existing Azure resource into state
terraform import 'azurerm_resource_group.main' \
  /subscriptions/50f529c1-ce1a-41ba-85ae-a60f5d0492bf/resourceGroups/rg-accountsvc-dev
```

### AKS Cluster

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-accountsvc-dev --name aks-accountsvc-dev

# Check cluster status
az aks show --resource-group rg-accountsvc-dev --name aks-accountsvc-dev --query "provisioningState" -o tsv

# List node pools and their scaling config
az aks nodepool list --resource-group rg-accountsvc-dev --cluster-name aks-accountsvc-dev --output table

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster events (last 20)
kubectl get events --sort-by='.lastTimestamp' -A | tail -20

# View cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50

# Check AKS available versions in region
az aks get-versions --location southafricanorth --output table

# Check available VM sizes in region
az vm list-sizes --location southafricanorth --output table | grep -i "Standard_B"

# Restart a node pool (scale to 0 then back)
az aks nodepool scale --resource-group rg-accountsvc-dev --cluster-name aks-accountsvc-dev --name app --node-count 0
az aks nodepool scale --resource-group rg-accountsvc-dev --cluster-name aks-accountsvc-dev --name app --node-count 1
```

### ACR (Container Registry)

```bash
# List ACR registries in the resource group
az acr list --resource-group rg-accountsvc-dev --output table

# Login to ACR
az acr login --name acraccountsvcdev5023

# List images in the registry
az acr repository list --name acraccountsvcdev5023 --output table

# Check AKS can pull from ACR
az aks check-acr --resource-group rg-accountsvc-dev --name aks-accountsvc-dev --acr acraccountsvcdev5023.azurecr.io

# Manually assign AcrPull role if the pipeline failed
KUBELET_ID=$(az aks show --resource-group rg-accountsvc-dev --name aks-accountsvc-dev --query "identityProfile.kubeletidentity.objectId" -o tsv)
ACR_ID=$(az acr show --name acraccountsvcdev5023 --query id -o tsv)
az role assignment create --assignee $KUBELET_ID --role AcrPull --scope $ACR_ID
```

### PostgreSQL

```bash
# Check server status
az postgres flexible-server show \
  --resource-group rg-accountsvc-dev \
  --name psql-accountsvc-dev \
  --query "state" -o tsv

# List databases
az postgres flexible-server db list \
  --resource-group rg-accountsvc-dev \
  --server-name psql-accountsvc-dev \
  --output table

# Check firewall/network rules
az postgres flexible-server show \
  --resource-group rg-accountsvc-dev \
  --name psql-accountsvc-dev \
  --query "network" -o json

# Test connectivity from a pod inside AKS
kubectl run pg-test --rm -it --image=postgres:16-alpine --restart=Never -- \
  psql "host=psql-accountsvc-dev.postgres.database.azure.com port=5432 dbname=fintech_accounts user=pgadmin password=YourStr0ngP@ss! sslmode=require"

# Restart the server
az postgres flexible-server restart \
  --resource-group rg-accountsvc-dev \
  --name psql-accountsvc-dev
```

### Kubernetes Workloads

```bash
# Check deployments
kubectl get deployments -n accountsvc-dev

# Check pods and their status
kubectl get pods -n accountsvc-dev -o wide

# Describe a failing pod
kubectl describe pod <POD_NAME> -n accountsvc-dev

# View pod logs
kubectl logs <POD_NAME> -n accountsvc-dev --tail=100

# View previous container logs (if it crashed)
kubectl logs <POD_NAME> -n accountsvc-dev --previous

# Check HPA status
kubectl get hpa -n accountsvc-dev

# Check services and endpoints
kubectl get svc,endpoints -n accountsvc-dev

# Check ingress
kubectl get ingress -n accountsvc-dev

# Force restart a deployment
kubectl rollout restart deployment/ms-account-service -n accountsvc-dev

# Watch pod status in real time
kubectl get pods -n accountsvc-dev -w
```

### Networking

```bash
# List VNets
az network vnet list --resource-group rg-accountsvc-dev --output table

# List subnets
az network vnet subnet list \
  --resource-group rg-accountsvc-dev \
  --vnet-name vnet-accountsvc-dev \
  --output table

# Check NSG rules
az network nsg rule list \
  --resource-group rg-accountsvc-dev \
  --nsg-name nsg-aks-dev \
  --output table

# Check private DNS zone records
az network private-dns record-set list \
  --resource-group rg-accountsvc-dev \
  --zone-name "accountsvc-dev.private.postgres.database.azure.com" \
  --output table
```

### Service Principal / OIDC (GitHub Actions)

```bash
# Check SP role assignments
az role assignment list \
  --assignee ac3fe376-97cc-48ae-bc8b-0922f78faf36 \
  --output table

# SP needs both of these roles:
#   - Contributor (create resources)
#   - User Access Administrator (create role assignments like AcrPull)

# Grant User Access Administrator if missing
az role assignment create \
  --assignee ac3fe376-97cc-48ae-bc8b-0922f78faf36 \
  --role "User Access Administrator" \
  --scope "/subscriptions/50f529c1-ce1a-41ba-85ae-a60f5d0492bf"

# Check federated credentials
az ad app federated-credential list \
  --id b62d9cbe-d986-457c-bbea-41f293a10a4c \
  --output table

# Check resource provider registrations
az provider show --namespace Microsoft.ContainerService --query "registrationState" -o tsv
az provider show --namespace Microsoft.ContainerRegistry --query "registrationState" -o tsv
az provider show --namespace Microsoft.DBforPostgreSQL --query "registrationState" -o tsv
az provider show --namespace Microsoft.Network --query "registrationState" -o tsv
az provider show --namespace Microsoft.OperationalInsights --query "registrationState" -o tsv

# Register a provider if not registered
az provider register --namespace Microsoft.ContainerService --wait
```

### Full Clean Reset (Nuclear Option)

If Terraform state and Azure resources are out of sync:

```bash
# 1. Delete the resource group (destroys all Azure resources)
az group delete --name rg-accountsvc-dev --yes --no-wait

# 2. Wait for deletion to complete
while [ "$(az group exists --name rg-accountsvc-dev)" = "true" ]; do
  echo "Waiting..." && sleep 10
done && echo "Resource group deleted"

# 3. Delete the Terraform state file
az storage blob delete \
  --account-name stfinsenseterraform \
  --container-name tfstate \
  --name "ms-account-service/dev.tfstate" \
  --auth-mode key \
  --account-key "$(az storage account keys list --resource-group rg-terraform-state --account-name stfinsenseterraform --query '[0].value' -o tsv)"

# 4. Trigger a fresh pipeline run
git commit --allow-empty -m "ci: trigger clean apply" && git push
```

---

## 🌍 Adding New Environments

1. Copy `envs/dev/` → `envs/staging/`
2. Update `terraform.tfvars` with environment-specific values
3. Copy `k8s/dev/` → `k8s/staging/` and adjust replicas, resources, ingress host
4. Add a new environment in `.github/workflows/terraform.yml`
5. Run `terraform init && terraform apply` from the new env directory

## 🔐 Security Notes

- PostgreSQL credentials should be passed via CLI vars or `TF_VAR_*` env vars — **never** commit passwords to git
- K8s secrets should be managed via [External Secrets Operator](https://external-secrets.io/) or [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) in production
- ACR uses managed identity (AcrPull role) — no image pull secrets needed
- AKS uses Azure RBAC with OIDC issuer and workload identity enabled
