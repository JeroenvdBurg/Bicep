# Bicep

Initial example repo for ARM templates using BICEP https://github.com/Azure/bicep

There are different modules

1. sql-server > deployed SQL server + firewall rules
2. sql-database > deployed SQL database within SQL server instance
3. storage-account > deployed storage account (optional globally redundancy 'Standard_GRS' : 'Standard_LRS)
4. app-service-plan > deployed app service plan
5. app-service > deployed app service + appinsight (optional deploy with staging slot)

deploy_all_modules > deployed full setup (storage, sql, web, cms, api)

## how to run bicep?

install the bicep CLI
https://github.com/Azure/bicep/blob/main/docs/installing.md

```
bicep build deploy_all_modules.bicep
```

generates ARM template

## Manual deploy ARM

Install the Azure CLI  
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

Login: `az login`  
Select subscription: `az account set --subscription "{subscriptionname}"`

Create a new resource group:
`az group create --name ResourceGroupName --location "West Europe"`

Deploy:

```
az deployment group create --name createTemplate --resource-group ResourceGroupName --template-file azuredeploy.json --parameters environment=dev --parameters sqlAdminPassword=Test123456! --parameters apiApiKey=Test123456!
```
