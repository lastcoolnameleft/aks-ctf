param vnetName string
param location string
param vnetAddressPrefix string = '10.224.0.0/12'
param subnetName string
param subnetPrefix string = '10.224.0.0/16'
param subnetNsgId string

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: subnetNsgId
          }
        }
      }
    ]
  }
}
output subnetId string = '${vnet.id}/subnets/${subnetName}'
