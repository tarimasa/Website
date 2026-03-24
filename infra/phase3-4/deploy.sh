#!/usr/bin/env bash
# =============================================================================
# Phase 3-4: Azure Static Web Apps デプロイスクリプト
# =============================================================================
set -euo pipefail

# -------------------------------------------------------
# 設定変数（環境に合わせて変更してください）
# -------------------------------------------------------
RESOURCE_GROUP="rg-portfolio"
LOCATION="eastasia"
APP_NAME="portfolio-website"
REPOSITORY_URL="https://github.com/tarimasa/Website"
BRANCH="main"
STORAGE_ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT_NAME:-}"  # Phase 1 で作成したもの

echo "====================================================="
echo " Phase 3-4: Static Web Apps デプロイ"
echo "====================================================="

# -------------------------------------------------------
# 1. ログイン確認
# -------------------------------------------------------
echo ""
echo "[1/4] Azure ログイン確認..."
if ! az account show &>/dev/null; then
  az login
fi
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "  サブスクリプション: ${SUBSCRIPTION_ID}"

# -------------------------------------------------------
# 2. GitHub デプロイトークン取得
# -------------------------------------------------------
echo ""
echo "[2/4] GitHub デプロイトークンの確認..."
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "  GITHUB_TOKEN 環境変数が未設定です"
  echo "  GitHub > Settings > Developer settings > Personal access tokens で生成してください"
  read -rsp "  GitHub PAT を入力してください: " GITHUB_TOKEN
  echo ""
fi

# -------------------------------------------------------
# 3. Bicep テンプレートで Static Web Apps デプロイ
# -------------------------------------------------------
echo ""
echo "[3/4] Bicep テンプレートで Static Web Apps をデプロイ..."

if [[ -z "${STORAGE_ACCOUNT_NAME}" ]]; then
  STORAGE_ACCOUNT_NAME=$(az storage account list \
    --resource-group "${RESOURCE_GROUP}" \
    --query "[0].name" \
    --output tsv)
  echo "  自動検出したストレージアカウント: ${STORAGE_ACCOUNT_NAME}"
fi

DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "$(dirname "$0")/main.bicep" \
  --parameters appName="${APP_NAME}" \
               repositoryUrl="${REPOSITORY_URL}" \
               branch="${BRANCH}" \
               repositoryToken="${GITHUB_TOKEN}" \
               blobStorageAccountName="${STORAGE_ACCOUNT_NAME}" \
  --query "properties.outputs" \
  --output json)

DEFAULT_HOSTNAME=$(echo "${DEPLOY_OUTPUT}" | jq -r '.defaultHostname.value')
MANAGED_IDENTITY_ID=$(echo "${DEPLOY_OUTPUT}" | jq -r '.managedIdentityPrincipalId.value')
DEPLOYMENT_TOKEN=$(echo "${DEPLOY_OUTPUT}" | jq -r '.deploymentToken.value')

echo "  Static Web Apps ホスト名 : ${DEFAULT_HOSTNAME}"
echo "  Managed Identity ID      : ${MANAGED_IDENTITY_ID}"

# -------------------------------------------------------
# 4. GitHub Actions シークレットに デプロイトークンを設定
# -------------------------------------------------------
echo ""
echo "[4/4] GitHub Actions シークレットを設定..."
if command -v gh &>/dev/null; then
  echo "${DEPLOYMENT_TOKEN}" | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN \
    --repo "tarimasa/Website"
  echo "  GitHub シークレット AZURE_STATIC_WEB_APPS_API_TOKEN を設定しました"
else
  echo "  gh CLI が見つかりません。手動でシークレットを設定してください:"
  echo "  GitHub > Settings > Secrets > AZURE_STATIC_WEB_APPS_API_TOKEN"
  echo "  値: ${DEPLOYMENT_TOKEN}"
fi

echo ""
echo "====================================================="
echo " Phase 3 完了！"
echo "====================================================="
echo ""
echo "次のステップ:"
echo "  1. Phase 4: ./setup-rbac.ps1 で RBAC 設定（PowerShell）"
echo "  2. Cloudflare DNS に CNAME レコードを追加:"
echo "     CNAME your-domain.com -> ${DEFAULT_HOSTNAME}"
echo "  3. GitHub に push してデプロイを確認"
echo "     https://${DEFAULT_HOSTNAME}"
