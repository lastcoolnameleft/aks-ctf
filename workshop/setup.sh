#!/bin/bash -e

########################################
# Functions
########################################

# Function to generate or load the values for environment variables
# and store them in a .env file
generateVars(){
  # Get users public IP
  MY_IP=$(curl -s icanhazip.com)
  K8SUSER=$RANDOM
  K8SPASSWORD=$RANDOM
  echo "This is your user/password for the webshell. Please keep it safe."
  echo "K8SUSER: $K8SUSER"
  echo "K8SPASSWORD: $K8SPASSWORD"
  K8SUSER_BASE64=$(echo -n $K8SUSER | base64)
  K8SPASSWORD_BASE64=$(echo -n $K8SPASSWORD | base64)

  # Check if the user provided values for the environment variables
  # If not, use the defaults
  export RESOURCE_GROUP="${RESOURCE_GROUP:-ctf-rg}"
  export LOCATION="${LOCATION:-westus}"
  export AKS_NAME="${AKS_NAME:-ctf-aks}"
  export VNET_NAME="${VNET_NAME:-ctf-vnet}"
  export AKS_SUBNET_NAME="${AKS_NAME:-aks-subnet}"
  export ACR_NAME=acr${RANDOM}

  # Generate an SSH key for the AKS cluster
  # TODO: We'll remove this once the disableSSH feature is GA in AKS
  echo "Generating Cluster SSH key..."
  ssh-keygen -N '' -f ./aks-ssh -t rsa

  # Create a .env file with the generated values
  # This can be used to reload the values if the script is run again
  cat <<EOF >.env
  MY_IP=$MY_IP
  K8SUSER=$K8SUSER
  K8SPASSWORD=$K8SPASSWORD
  K8SUSER_BASE64=$K8SUSER_BASE64
  K8SPASSWORD_BASE64=$K8SPASSWORD_BASE64
  RESOURCE_GROUP=$RESOURCE_GROUP
  LOCATION=$LOCATION
  AKS_NAME=$AKS_NAME
  VNET_NAME=$VNET_NAME
  AKS_SUBNET_NAME=$AKS_SUBNET_NAME
  ACR_NAME=$ACR_NAME 
EOF
}

# Function to load the values from the .env file
loadExistingVars(){
  source ./.env
  echo "MY_IP: $MY_IP"
  echo "K8SUSER: $K8SUSER"
  echo "K8SPASSWORD: $K8SPASSWORD"
  echo "K8SUSER_BASE64: $K8SUSER_BASE64"
  echo "K8SPASSWORD_BASE64: $K8SPASSWORD_BASE64"
  echo "RESOURCE_GROUP: $RESOURCE_GROUP"
  echo "LOCATION: $LOCATION"
  echo "AKS_NAME: $AKS_NAME"
  echo "VNET_NAME: $VNET_NAME"
  echo "AKS_SUBNET_NAME: $AKS_SUBNET_NAME"
  echo "ACR_NAME: $ACR_NAME"
}

# Function to deploy the Azure resources
deployAzureResources(){

echo "Deploying Azure resources..."

# Create the resource group
az group create -n $RESOURCE_GROUP -l $LOCATION

# Deploy the Vnet, ACR and AKS Cluster via Bicep
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters location=${LOCATION} \
               vnetName=${VNET_NAME} \
               vnetAddressPrefix=10.224.0.0/12 \
               subnetName=mySubnet \
               subnetPrefix=10.224.0.0/16 \
               aksClusterName=${AKS_NAME} \
               acrName=${ACR_NAME} \
               aksNodeCount=3 \
               aksNodeSize=Standard_DS2_v2 \
               userIP=${MY_IP} \
               sshPublicKey="$(cat ./aks-ssh.pub)"

# Attach AKS to ACR
az aks update -n $AKS_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME
}

# Function to deploy the Kubernetes resources
deployKubernetesResources(){
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

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
  --docker-password $ACR_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

# build the app image
az acr build -r $ACR_NAME --image insecure-app ./insecure-app/

cat <<EOF >>./manifests/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- omnibus.yml
images:
- name: lastcoolnameleft/insecure-app
  newName: ${ACR_NAME}.azurecr.io/insecure-app
EOF

kubectl apply -k ./manifests
}

getClusterAndACRCreds(){
# Get the ACR Credentials
ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query 'passwords[0].value' -o tsv)

# Fetch a valid kubeconfig
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing 
# Grab a copy for scenario 1
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin --overwrite-existing --file ./scenario_1/kubeconfig

}
########################################
# End of Functions
########################################

########################################
# Main Script
########################################

# Generate or load existing values for the environment variables
if ! [ -f ./.env ]; then
echo "Loading and generating values for the environment variables..."
generateVars
else
# Load the values from the existing .env file
echo "File .env exists. Loading values from .env file..."
loadExistingVars
fi

# Deploy the Azure resources
echo "Deploying Azure resources..."
deployAzureResources

# Get the cluster and ACR credentials
echo "Getting the cluster and ACR credentials..."
getClusterAndACRCreds

# Deploy the Kubernetes resources
echo "Deploying Kubernetes resources..."
deployKubernetesResources


########################################
# End Main Script
########################################
