@description('Azure Blob Storage for website images')
param location string = 'japaneast'

@description('Storage account name (globally unique, 3-24 chars, lowercase alphanumeric)')
param storageAccountName string = 'websiteblob${uniqueString(resourceGroup().id)}'

@description('Container name for storing blog images')
param containerName string = 'images'

@description('Allow public read access to images container')
param enablePublicAccess bool = true

// -------------------------------------------------------
// Storage Account
// -------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: enablePublicAccess
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'  // 後でPhase4でAzureServicesのみに制限
      bypass: 'AzureServices'
    }
  }
}

// -------------------------------------------------------
// Blob Service 設定
// -------------------------------------------------------
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: [
        {
          allowedHeaders: ['*']
          allowedMethods: ['GET', 'HEAD']
          allowedOrigins: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

// -------------------------------------------------------
// Images コンテナ（ブログ画像用）
// -------------------------------------------------------
resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: enablePublicAccess ? 'Blob' : 'None'
    metadata: {
      purpose: 'blog-images'
    }
  }
}

// -------------------------------------------------------
// Outputs
// -------------------------------------------------------
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
output containerName string = containerName
output imagesBaseUrl string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'
