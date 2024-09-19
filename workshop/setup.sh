#!/bin/bash -e

########################################
# Data Gathering

K8SUSER=$RANDOM
K8SPASSWORD=$RANDOM
echo "This is your user/password for the webshell. Please keep it safe."
echo "K8SUSER: $K8SUSER"
echo "K8SPASSWORD: $K8SPASSWORD"
K8SUSER_BASE64=$(echo -n $K8SUSER | base64)
K8SPASSWORD_BASE64=$(echo -n $K8SPASSWORD | base64)

########################################
# Project Setup
echo
echo "Create resource group..."
echo
export RESOURCE_GROUP="${RESOURCE_GROUP:-ctf-rg}"
export LOCATION="${LOCATION:-westus}"
export AKS_NAME="${AKS_NAME:-ctf-aks}"
export VNET_NAME="${VNET_NAME:-ctf-vnet}"
export AKS_SUBNET_NAME="${AKS_NAME:-aks-subnet}"
export ACR_NAME=acr${RANDOM}

az group create --name $RESOURCE_GROUP --location $LOCATION

az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefixes 10.224.0.0/12 \
    --subnet-name $AKS_SUBNET_NAME \
    --subnet-prefix 10.224.0.0/16 \
    --location $LOCATION

AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_NAME --query id -o tsv)
echo "AKS_SUBNET_ID: $AKS_SUBNET_ID"

########################################
# Create an Azure Container Registry
az acr create -g $RESOURCE_GROUP -n $ACR_NAME --sku Basic --admin-enabled true
# Import images to ACR
az acr import -n $ACR_NAME --source docker.io/lastcoolnameleft/insecure-app:latest --image insecure-app

# Get the ACR Credentials
ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query 'passwords[0].value' -o tsv)

########################################
# Create a Cluster
echo
echo "Deploying cluster..."
echo

AKS_CLUSTER_ID=$(az aks create -g $RESOURCE_GROUP -n $AKS_NAME -l $LOCATION \
  --node-count 1 \
  --node-vm-size Standard_B4as_v2 \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --enable-addons monitoring \
  --no-ssh-key \
  --query id -o tsv)

# Create a log analytics workspace for monitoring the cluster
WORKSPACE_ID=$(az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name ctf-workspace \
  --location $LOCATION \
  --query id -o tsv)

# Enable kube-audit-admin
az monitor diagnostic-settings create --name AKS-Diagnostics --resource $AKS_CLUSTER_ID \
  --logs '[
    {"category": "kube-audit", "enabled": false},
    {"category": "kube-audit-admin", "enabled": true},
    {"category": "kube-apiserver", "enabled": false},
    {"category": "kube-controller-manager", "enabled": true},
    {"category": "kube-scheduler", "enabled": true},
    {"category": "cluster-autoscaler", "enabled": true},
    {"category": "cloud-controller-manager", "enabled": true},
    {"category": "guard", "enabled": true},
    {"category": "csi-azuredisk-controller", "enabled": true},
    {"category": "csi-azurefile-controller", "enabled": true},
    {"category": "csi-snapshot-controller", "enabled": true}
  ]' \
  --workspace $WORKSPACE_ID \
  --export-to-resource-specific true

# Fetch a valid kubeconfig
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing 
# Grab a copy for scenario 1
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing --file ./scenario_1/kubeconfig

########################################
# Apply the k8s config

kubectl create namespace dev
kubectl create namespace prod

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: dev
type: Opaque
data:
  username: $K8SUSER_BASE64
  password: $K8SPASSWORD_BASE64
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: prod
type: Opaque
data:
  username: $K8SUSER_BASE64
  password: $K8SPASSWORD_BASE64
EOF

# Create the registry credentials
kubectl create secret docker-registry acr-secret \
  --namespace dev \
  --docker-server $ACR_NAME.azurecr.io \
  --docker-username $ACR_USERNAME \
  --docker-password $ACR_PASSWORD

cat <<EOF >>./workshop/manifests/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- omnibus.yml
images:
- name: lastcoolnameleft/insecure-app
  newName: ${ACR_NAME}.azurecr.io/insecure-app
EOF

kubectl apply -k ./workshop/manifests


# Restrict access to services to just the user's IP
# NOTE: Not sure this is needed anymore.
# az network nsg list -g secure-k8s-nodepool-rg -o json | jq -r '.[0].name'

### ISSUE: Unable to install nmap ()
# yum install nmap
# Error(1601) : Operation not permitted. You have to be root.
# ALT: Provide statically linked binary?
#if ! [ -x "$(command -v nmap)" ]; then
#  echo -n "Installing nmap..."
#  sudo DEBIAN_FRONTEND=noninteractive apt-get update -q 1> /dev/null 2> /dev/null
#  sudo DEBIAN_FRONTEND=noninteractive apt-get install nmap -y -q 1> /dev/null 2> /dev/null
#  echo "done."
#  exit 1
#fi
