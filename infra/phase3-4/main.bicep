@description('Azure Static Web Apps + RBAC 設定のメインテンプレート')
param location string = 'eastasia'

@description('Static Web Apps のリソース名')
param appName string = 'portfolio-website'

@description('GitHub リポジトリ URL (例: https://github.com/username/repo)')
param repositoryUrl string

@description('デプロイ対象ブランチ')
param branch string = 'main'

@description('GitHub Personal Access Token（デプロイトークン）')
@secure()
param repositoryToken string

@description('Blob Storage アカウント名（Phase 1 で作成済み）')
param blobStorageAccountName string

@description('Blob Storage リソースグループ（Phase 1 と同じ場合は同じ値）')
param blobStorageResourceGroup string = resourceGroup().name

// -------------------------------------------------------
// モジュール: Static Web Apps
// -------------------------------------------------------
module staticWebApp 'static-web-app.bicep' = {
  name: 'staticWebAppDeploy'
  params: {
    location: location
    appName: appName
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: repositoryToken
  }
}

// -------------------------------------------------------
// Blob Storage への RBAC 割り当て
// Storage Blob Data Reader ロール
// -------------------------------------------------------
resource blobStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: blobStorageAccountName
  scope: resourceGroup(blobStorageResourceGroup)
}

// Storage Blob Data Reader ロール定義 ID（組み込みロール）
var storageBlobDataReaderRoleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(blobStorage.id, staticWebApp.outputs.managedIdentityPrincipalId, storageBlobDataReaderRoleId)
  scope: blobStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataReaderRoleId)
    principalId: staticWebApp.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Static Web Apps Managed Identity -> Storage Blob Data Reader'
  }
}

// -------------------------------------------------------
// Outputs
// -------------------------------------------------------
output staticWebAppId string = staticWebApp.outputs.staticWebAppId
output defaultHostname string = staticWebApp.outputs.defaultHostname
output managedIdentityPrincipalId string = staticWebApp.outputs.managedIdentityPrincipalId
output deploymentToken string = staticWebApp.outputs.deploymentToken
