@description('Azure Blob Storage for website images (private container)')
param location string = 'japaneast'

@description('Storage account name (globally unique, 3-24 chars, lowercase alphanumeric)')
param storageAccountName string = 'websiteblob${uniqueString(resourceGroup().id)}'

@description('Container name for storing blog images')
param containerName string = 'images'

// -------------------------------------------------------
// Storage Account（パブリックアクセス無効・プライベート構成）
// -------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false        // パブリックアクセス完全無効
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'      // Entra ID 認証経由でアクセス可
    networkAcls: {
      defaultAction: 'Allow'
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
      corsRules: []  // プライベートのため CORS 不要
    }
  }
}

// -------------------------------------------------------
// images コンテナ（プライベート・App Registration 経由でのみアクセス可）
// -------------------------------------------------------
resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'   // 匿名アクセス無効
    metadata: {
      purpose: 'blog-images'
      accessControl: 'entra-id-app-registration'
    }
  }
}

// -------------------------------------------------------
// Outputs
// -------------------------------------------------------
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output storageAccountBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output containerName string = containerName
