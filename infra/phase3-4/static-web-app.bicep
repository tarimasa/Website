@description('Azure Static Web Apps リソース定義（Freeプラン）')
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
// Azure Static Web Apps（Free プラン）
// Free プランは Managed Identity 非対応
// 代わりに Entra ID App Registration を使用（setup-app-registration.sh で設定）
// -------------------------------------------------------
resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: appName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: '/'
      outputLocation: 'out'
      skipGithubActionWorkflowGeneration: true  // 手動管理の workflow を使用
    }
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
  }
}

// -------------------------------------------------------
// Outputs
// -------------------------------------------------------
output staticWebAppId string = staticWebApp.id
output defaultHostname string = staticWebApp.properties.defaultHostname
