@description('The name of the App Service Plan.')
param appServicePlanName string

@description('The name of the Web App.')
param webAppName string

@description('The SKU for the App Service Plan. Example: B1, P1v2')
param skuName string = 'B1'

@description('The location for the resources.')
param location string = resourceGroup().location

@description('The version of the .NET runtime stack.')
param dotNetVersion string = 'DOTNETCORE|6.0' // This can stay if you're using .NET

@description('Tags to assign to the resources.')
param tags object = {}

param sqlServerName string 
param sqlDatabasename string 
param administratorLogin string 

@secure()
param administratorPassword string 

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: skuName == 'B1' ? 'Basic' : 'PremiumV2'
    capacity: 1
  }
  properties: {
    reserved: false // Set to false to indicate it's a Windows plan
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: null // Set to null to indicate Windows
      windowsFxVersion: dotNetVersion // Specify the .NET version for Windows
    }
    httpsOnly: false
  }
  tags: tags
}

resource connectionString 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: webApp
  name: 'connectionstrings'
  properties: {
    DefaultConnection: {
      type: 'SQLAzure'
      value: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabasename};User Id=${administratorLogin}@${sqlServerName};Password=${administratorPassword};'
    }
  }
}

output webAppEndpoint string = webApp.properties.defaultHostName
output webAppId string = webApp.id
output appServicePlanId string = appServicePlan.id
output webApp object = webApp
