param sqlServerName string
param location string = resourceGroup().location
param databaseName string

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlServerName}/${databaseName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}