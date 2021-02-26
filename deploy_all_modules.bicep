param company string {
  minLength: 3
  maxLength: 24
  default: 'company'
}
param environment string {
  minLength: 3
  maxLength: 24
  default: 'dev'
}
param adminLogin string {
  metadata: {
    description: 'The admin user of the SQL Server'
  }
  default: 'SQLadmin'
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
var location = resourceGroup().location
var storageName = '${uniqueName}data'
var uniqueName = concat(company, environment)
var nconfigAlias = environment
var appServicePlanName = '${uniqueName}-plan'
var webAppName = '${uniqueName}-web'
var cmsAppName = '${uniqueName}-cms'
var apiAppName = '${uniqueName}-api'
var sqlServerName = '${uniqueName}sqlserver'
var databaseName = '${uniqueName}db'
var keyVaultName = '${uniqueName}vault'

//create storage account
module StorageAccountModule './storage-account.bicep' = {
  name: 'storageAccountDeploy'
  params: {
    storageAccountName: storageName
  }
}

//create SQL server
module SqlServerModule './sql-server.bicep' = {
  name: 'sqlServerDeploy'
  params: {
    sqlServerName: sqlServerName
    sqlAdminLogin: adminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

//Create SQL database
module SqlDatabaseModule './sql-database.bicep' = {
  name: 'sqlDatabaseDeploy'
  params: {
    sqlServerName: sqlServerName
    databaseName: databaseName
  }
  dependsOn: [
    SqlServerModule
  ]
}

//create app service plan
module appServicePlanModule './app-service-plan.bicep' = {
  name: 'appServicePlanDeploy'
  params: {
    appServicePlanName: appServicePlanName
  }
}
var appServicePlanID = appServicePlanModule.outputs.appServicePlanID

/////////////////////WEB/////////////////////////////

//create webapp (prod/staging)
module appServiceWeb './app-service.bicep' = {
  name: 'appServiceWeb'
  params: {
    appName: webAppName
    appServicePlanID: appServicePlanID
    KeyVaultName: keyVaultName
    nconfigAlias: nconfigAlias
  }
}

/////////////////////CMS/////////////////////////////

//create cmsapp (prod/staging)
module appServiceCMS './app-service.bicep' = {
  name: 'appServiceCMS'
  params: {
    appName: cmsAppName
    appServicePlanID: appServicePlanID
    KeyVaultName: keyVaultName
    nconfigAlias: nconfigAlias
  }
}
/////////////////////////////////////////////////////

/////////////////////API/////////////////////////////

//create APIapp (prod/staging)
module appServiceAPI './app-service.bicep' = {
  name: 'appServiceAPI'
  params: {
    appName: apiAppName
    appServicePlanID: appServicePlanID
    KeyVaultName: keyVaultName
    nconfigAlias: nconfigAlias
  }
}