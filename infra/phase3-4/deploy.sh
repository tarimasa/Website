#!/usr/bin/env bash
# =============================================================================
# Phase 3: Azure Static Web Apps デプロイスクリプト
# =============================================================================
set -euo pipefail

RESOURCE_GROUP="Website"
LOCATION="eastasia"
APP_NAME="portfolio-website"
REPOSITORY_URL="https://github.com/tarimasa/Website"
BRANCH="main"
GITHUB_REPO="tarimasa/Website"

echo "====================================================="
echo " Phase 3: Static Web Apps デプロイ（Freeプラン）"
echo "====================================================="

echo ""
echo "[1/3] Azure ログイン確認..."
if ! az account show &>/dev/null; then
  az login
fi
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "  サブスクリプション: ${SUBSCRIPTION_ID}"

echo ""
echo "[2/3] GitHub トークン確認..."
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "  GITHUB_TOKEN 環境変数が未設定です"
  read -rsp "  GitHub PAT を入力してください: " GITHUB_TOKEN
  echo ""
fi

echo ""
echo "[3/3] Bicep テンプレートで Static Web Apps をデプロイ..."
DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "$(dirname "$0")/main.bicep" \
  --parameters appName="${APP_NAME}" \
               repositoryUrl="${REPOSITORY_URL}" \
               branch="${BRANCH}" \
               repositoryToken="${GITHUB_TOKEN}" \
  --query "properties.outputs" \
  --output json)

DEFAULT_HOSTNAME=$(echo "${DEPLOY_OUTPUT}" | jq -r '.defaultHostname.value')

echo "  Static Web Apps ホスト名: ${DEFAULT_HOSTNAME}"

# デプロイトークンを az コマンドで取得
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
  --name "${APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "properties.apiKey" -o tsv)

# GitHub Actions シークレットにデプロイトークンを設定
if command -v gh &>/dev/null; then
  echo "${DEPLOYMENT_TOKEN}" | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN \
    --repo "${GITHUB_REPO}"
  echo "  GitHub Secrets: AZURE_STATIC_WEB_APPS_API_TOKEN を設定しました"
else
  echo "  手動で GitHub Secrets に設定してください:"
  echo "  AZURE_STATIC_WEB_APPS_API_TOKEN = ${DEPLOYMENT_TOKEN}"
fi

echo ""
echo "====================================================="
echo " Phase 3 完了！"
echo "====================================================="
echo ""
echo "  サイトURL: https://${DEFAULT_HOSTNAME}"
echo ""
echo "次のステップ:"
echo "  1. GitHub に push → GitHub Actions が自動デプロイ"
echo "  2. Cloudflare DNS に CNAME を追加:"
echo "     CNAME your-domain.com -> ${DEFAULT_HOSTNAME}"
