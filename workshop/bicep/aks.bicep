param location string = resourceGroup().location
param aksClusterName string
param aksNodeCount int
param aksNodeSize string
param subnetId string
param aksAdminUsername string
param workspaceId string
param sshPublicKey string

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksClusterName
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceId
        }
      }
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: aksNodeCount
        vmSize: aksNodeSize
        vnetSubnetID: subnetId
        osType: 'Linux'
        mode: 'System'
      }
    ]
    linuxProfile: {
      adminUsername: aksAdminUsername
      ssh: {
        publicKeys: [ 
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
  }
}

resource aksDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'aksDiagnosticSettings'
  scope: aks
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
      }
      {
        category: 'cloud-controller-manager'
        enabled: true
      }
      {
        category: 'guard'
        enabled: true
      }
      {
        category: 'csi-azuredisk-controller'
        enabled: true
      }
      {
        category: 'csi-azurefile-controller'
        enabled: true
      }
      {
        category: 'csi-snapshot-controller'
        enabled: true
      }
    ]
  }
}
