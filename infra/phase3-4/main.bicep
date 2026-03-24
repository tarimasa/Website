@description('ポートフォリオサイト Azure Static Web Apps デプロイ（Freeプラン）')
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

// -------------------------------------------------------
// モジュール: Static Web Apps（Free プラン）
// RBAC 設定は setup-app-registration.sh（Graph API + ARM API）で実施済み
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
// Outputs
// -------------------------------------------------------
output staticWebAppId string = staticWebApp.outputs.staticWebAppId
output defaultHostname string = staticWebApp.outputs.defaultHostname
