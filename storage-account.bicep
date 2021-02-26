param location string = resourceGroup().location
param storageAccountName string
param globalRedundancy bool = true // defaults to true, but can be overridden

resource StorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  tags: {
    displayName: 'Storage'
  }
  sku: {
    name: globalRedundancy ? 'Standard_GRS' : 'Standard_LRS' // if true --> GRS, else --> LRS
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}