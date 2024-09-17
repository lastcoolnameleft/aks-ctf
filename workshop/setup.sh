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
export RESOURCE_GROUP="aks-ctf-rg"
export LOCATION="westus"
export AKS_NAME="aks-ctf"
export AKS_NODEPOOL_RG="aks-ctf-nodepool-rg"
az group create --name $RESOURCE_GROUP --location $LOCATION

########################################
# Create a Cluster
echo
echo "Deploying cluster..."
echo

az aks create -g $RESOURCE_GROUP -n $AKS_NAME -l $LOCATION \
    --node-count 1 \
    --node-vm-size Standard_B4as_v2 \
    --node-resource-group $AKS_NODEPOOL_RG \
    --pod-cidr 192.168.0.0/16 \
    --network-plugin azure \
    --network-plugin-mode overlay \
    --enable-addons monitoring \
    --no-ssh-key

# Fetch a valid kubeconfig
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing 
# Grab a copy for scenario 1
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing --file /scenario_1/kubeconfig

########################################
# Apply the k8s config

kubectl create namespace dev
kubectl create namespace prd

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-secret
  namespace: dev
type: Opaque
data:
  username: $K8SUSER_BASE64
  password: $K8SPASSWORD_BASE64
---
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-secret
  namespace: prd
type: Opaque
data:
  username: $K8SUSER_BASE64
  password: $K8SPASSWORD_BASE64
EOF

kubectl apply -f omnibus.yml


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
