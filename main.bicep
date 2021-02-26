param company string {
  minLength: 3
  maxLength: 24
  default: 'europcar'
}
param environment string {
  minLength: 3
  maxLength: 24
  default: 'dev'
}
var location = resourceGroup().location
param adminLogin string {
  metadata: {
    description: 'The admin user of the SQL Server'
  }
  default: 'europcaradmin'
}
param apiApiKey string {
  metadata: {
    description: 'The API api secret'
  }
  secure: true
}
param sqlAdminPassword string {
  metadata: {
    description: 'The password of the admin user of the SQL Server'
  }
  secure: true
}
param tenantId string {
  metadata: {
    description: 'Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.'
  }
  default: subscription().tenantId
}

var uniqueName = concat(company, environment)
var nconfigAlias = environment
var storageName_var = '${uniqueName}data'
var appServicePlanName_var = '${uniqueName}-plan'
var webAppName = '${uniqueName}-web'
var cmsAppName = '${uniqueName}-cms'
var apiAppName = '${uniqueName}-api'
var logicAppNameAVS_var = '${uniqueName}-logicapp-avs'
var logicAppNameGeoNames_var = '${uniqueName}-logicapp-geonames'
var appInsightsWebName_var = '${webAppName}-insights'
var appInsightsCmsName_var = '${cmsAppName}-insights'
var appInsightsApiName_var = '${apiAppName}-insights'
var sqlServerName_var = '${uniqueName}sqlserver'
var databaseName = '${uniqueName}db'
var keyVaultName_var = '${uniqueName}vault'

resource storageName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageName_var
  location: location
  tags: {
    displayName: 'Storage'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource sqlServer 'Microsoft.Sql/servers@2014-04-01' = {
  name: sqlServerName_var
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlServer.name}/${databaseName}'
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

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2015-05-01-preview' = {
  name: '${sqlServer.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource appInsightsWeb 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsWebName_var
  location: location
  kind: 'string'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${webAppName}': 'Resource'
    displayName: 'Application Insights Web'
  }
  properties: {
    Application_Type: 'web'
  }
}

resource appInsightsCms 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsCmsName_var
  location: location
  kind: 'string'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${cmsAppName}': 'Resource'
    displayName: 'Application Insights CMS'
  }
  properties: {
    Application_Type: 'web'
  }
}

resource appInsightsApi 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsApiName_var
  location: location
  kind: 'string'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${apiAppName}': 'Resource'
    displayName: 'Application Insights API'
  }
  properties: {
    Application_Type: 'web'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  kind: 'app'
  name: appServicePlanName_var
  location: location
  tags: {
    displayName: 'App Service Plan'
  }
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'app'
  name: webAppName
  location: location
  tags: {
    displayName: 'Web App'
  }
  properties: {
    serverFarmId: appServicePlan.id
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

  dependsOn: [
    appInsightsWeb
  ]
}

resource webApp_appsettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webApp.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsWeb.properties.InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    webApp
  ]
}

resource webApp_staging 'Microsoft.Web/sites/slots@2018-11-01' = {
  kind: 'app'
  name: '${webApp.name}/staging'
  location: location
  tags: {
    displayName: 'Web App Staging slot'
  }
  properties: {
    serverFarmId: appServicePlan.id
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

resource webApp_staging_appsettings 'Microsoft.Web/sites/slots/config@2018-11-01' = {
  name: '${webApp_staging.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('Microsoft.Insights/components/${appInsightsWebName_var}').InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
}

resource cmsApp 'Microsoft.Web/sites@2018-11-01' = {
  kind: 'app'
  name: cmsAppName
  location: location
  tags: {
    displayName: 'CMS App'
  }
  properties: {
    serverFarmId: appServicePlan.id
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
  dependsOn: [
    appInsightsCms
  ]
}

resource cmsApp_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: '${cmsApp.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('microsoft.insights/components/${appInsightsCmsName_var}').InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
}

resource cmsApp_staging 'Microsoft.Web/sites/slots@2018-11-01' = {
  kind: 'app'
  name: '${cmsApp.name}/staging'
  location: location
  tags: {
    displayName: 'CMS App Staging slot'
  }
  properties: {
    serverFarmId: appServicePlan.id
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

resource cmsApp_staging_appsettings 'Microsoft.Web/sites/slots/config@2018-11-01' = {
  name: '${webApp_staging.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('microsoft.insights/components/${appInsightsCmsName_var}').InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    cmsApp_staging
  ]
}

resource apiApp 'Microsoft.Web/sites@2018-11-01' = {
  kind: 'app'
  name: apiAppName
  location: location
  tags: {
    displayName: 'API App'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      http20Enabled: true
      netFrameworkVersion: 'v5.0'
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    appInsightsCms
  ]
}

resource apiApp_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: '${apiApp.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('microsoft.insights/components/${appInsightsApiName_var}').InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
}

resource apiApp_staging 'Microsoft.Web/sites/slots@2018-11-01' = {
  kind: 'app'
  name: '${apiApp.name}/staging'
  location: location
  tags: {
    displayName: 'API App Staging slot'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      http20Enabled: true
      netFrameworkVersion: 'v5.0'
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apiApp_staging_appsettings 'Microsoft.Web/sites/slots/config@2018-11-01' = {
  name: '${webApp_staging.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('microsoft.insights/components/${appInsightsApiName_var}').InstrumentationKey
    NCONFIG_ALIAS: nconfigAlias
    KEYVAULT: keyVaultName_var
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_ENABLE_SYNC_UPDATE_SITE: 'true'
  }
  dependsOn: [
    apiApp_staging
  ]
}

resource keyVaultName 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName_var
  location: location
  tags: {
    displayName: 'KeyVault'
  }
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: 'ca10762d-1d4b-4939-853f-535ab725a6ee'
        tenantId: tenantId
        permissions: {
          keys: [
            'All'
          ]
          secrets: [
            'All'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(cmsAppName_resource.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(cmsAppName_staging.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(webAppName_resource.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(webAppName_staging.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(apiAppName_resource.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: reference(apiAppName_staging.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      value: {
        defaultAction: 'Allow'
        bypass: 'AzureServices'
      }
    }
  }
}

resource logicAppNameAVS 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicAppNameAVS_var
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Day'
            interval: 1
            startTime: '01-01-2021 00:00:00'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        'Branch Categories': {
          runAfter: {
            Categories: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            headers: {
              'x-api-key': apiApiKey
            }
            method: 'POST'
            uri: 'https://${apiAppName_var}.azurewebsites.net/scheduled/synchronize-avs-branch-categories'
          }
        }
        Branches: {
          runAfter: {}
          type: 'Http'
          inputs: {
            headers: {
              'x-api-key': apiApiKey
            }
            method: 'POST'
            uri: 'https://${apiAppName_var}.azurewebsites.net/scheduled/synchronize-avs-branches'
          }
        }
        Categories: {
          runAfter: {
            Branches: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            headers: {
              'x-api-key': apiApiKey
            }
            method: 'POST'
            uri: 'https://${apiAppName_var}.azurewebsites.net/scheduled/synchronize-avs-categories'
          }
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

resource logicAppNameGeoNames 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicAppNameGeoNames_var
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Week'
            interval: 1
            startTime: '01-01-2021 00:00:00'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        places: {
          runAfter: {
            postal_codes: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            headers: {
              'x-api-key': apiApiKey
            }
            method: 'POST'
            uri: 'https://${apiAppName_var}.azurewebsites.net/scheduled/synchronize-places'
          }
        }
        postal_codes: {
          runAfter: {}
          type: 'Http'
          inputs: {
            headers: {
              'x-api-key': apiApiKey
            }
            method: 'POST'
            uri: 'https://${apiAppName_var}.azurewebsites.net/scheduled/synchronize-postal-codes'
          }
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

resource keyVaultName_BlobStorageConfig_StorageAccount 'Microsoft.KeyVault/vaults/secrets@2015-06-01' = {
  name: '${keyVaultName.name}/BlobStorageConfig--StorageAccount'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageName_var};AccountKey=${listKeys(storageName.id, providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value};'
  }
}

resource keyVaultName_ApiConfiguration_ApiKey 'Microsoft.KeyVault/vaults/secrets@2015-06-01' = {
  name: '${keyVaultName.name}/ApiConfiguration--ApiKey'
  properties: {
    value: apiApiKey
  }
}

resource keyVaultName_ConnectionStrings_DefaultConnection 'Microsoft.KeyVault/vaults/secrets@2015-06-01' = {
  name: '${keyVaultName.name}/ConnectionStrings--DefaultConnection'
  properties: {
    value: 'Data Source=tcp:${sqlServerName_var}.database.windows.net,1433;Initial Catalog=${databaseName};User Id=${adminLogin};Password=${sqlAdminPassword};'
  }
  dependsOn: [
    sqlServerName
  ]
}

output webApp_name string = webAppName
output cmsApp_name string = cmsAppName
output ApiApp_name string = apiAppName
output sql string = reference('Microsoft.Sql/servers/${sqlServerName_var}').fullyQualifiedDomainName