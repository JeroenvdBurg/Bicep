param appInsightsName string
param location string = resourceGroup().location

resource appInsights 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: {
    displayName: 'Application Insights'
  }
  properties: {
    Application_Type: 'web'
  }
}