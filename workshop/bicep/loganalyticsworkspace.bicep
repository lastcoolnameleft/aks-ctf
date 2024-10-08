param location string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'name'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
