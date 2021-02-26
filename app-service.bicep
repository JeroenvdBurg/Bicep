param location string = resourceGroup().location
param appName string
param appInsightsName string = '${appName}-insights'
param appServicePlanID string
param KeyVaultName string
param nconfigAlias string
param deployStaging bool = true

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
var APPINSIGHTS_INSTRUMENTATIONKEY = appInsights.properties.InstrumentationKey

resource AppService 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'app'
  name: appName
  location: location
  tags: {
    displayName: 'Web App'
  }
  properties: {
    serverFarmId: appServicePlanID
    siteConfig: {
      appSettings: []
      alwaysOn: true
      http20Enabled: true
      netFrameworkVersion: 'v5.0'
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource AppService_settings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${AppService.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: APPINSIGHTS_INSTRUMENTATIONKEY
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: KeyVaultName
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    AppService
  ]
}

resource AppService_staging 'Microsoft.Web/sites/slots@2018-11-01' = if (deployStaging) {
  kind: 'app'
  name: '${AppService.name}/staging'
  location: location
  tags: {
    displayName: 'Web App Staging slot'
  }
  properties: {
    serverFarmId: appServicePlanID
    siteConfig: {
      alwaysOn: true
      http20Enabled: true
      netFrameworkVersion: 'v5.0'
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource webApp_staging_appsettings 'Microsoft.Web/sites/slots/config@2018-11-01' = if (deployStaging) {
  name: '${AppService_staging.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: APPINSIGHTS_INSTRUMENTATIONKEY
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: KeyVaultName
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    AppService_staging
  ]
}