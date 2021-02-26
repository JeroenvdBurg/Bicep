param skuName string = 'S1'
param skuCapacity int = 1
param location string = resourceGroup().location
param appServicePlanName string

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  tags: {
    displayName: 'App Service Plan'
    ProjectName: appServicePlanName
  }
}
output appServicePlanID string = appServicePlan.id