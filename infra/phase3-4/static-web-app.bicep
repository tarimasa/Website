@description('Azure Static Web Apps リソース定義')
param location string = 'eastasia'

@description('Static Web Apps のリソース名')
param appName string = 'portfolio-website'

@description('GitHub リポジトリ URL')
param repositoryUrl string

@description('デプロイ対象ブランチ')
param branch string = 'main'

@description('GitHub Personal Access Token')
@secure()
param repositoryToken string

// -------------------------------------------------------
// Azure Static Web Apps（Standard プラン）
// ※ Managed Identity は Standard プラン以上で使用可能
// -------------------------------------------------------
resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: appName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'  // Managed Identity を有効化
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: '/'
      outputLocation: 'out'
      skipGithubActionWorkflowGeneration: false
    }
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
  }
}

// -------------------------------------------------------
// カスタムドメイン設定（オプション）
// -------------------------------------------------------
// resource customDomain 'Microsoft.Web/staticSites/customDomains@2022-09-01' = {
//   parent: staticWebApp
//   name: 'your-domain.com'
//   properties: {}
// }

// -------------------------------------------------------
// Outputs
// -------------------------------------------------------
output staticWebAppId string = staticWebApp.id
output defaultHostname string = staticWebApp.properties.defaultHostname
output managedIdentityPrincipalId string = staticWebApp.identity.principalId
output deploymentToken string = listSecrets(staticWebApp.id, staticWebApp.apiVersion).properties.apiKey
