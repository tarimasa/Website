#!/usr/bin/env bash
# =============================================================================
# Phase 1: Azure Blob Storage セットアップスクリプト
# 使用技術: Azure CLI + Bicep
# =============================================================================
set -euo pipefail

# -------------------------------------------------------
# 設定変数（環境に合わせて変更してください）
# -------------------------------------------------------
RESOURCE_GROUP="rg-portfolio"
LOCATION="japaneast"
STORAGE_ACCOUNT_NAME="websiteblob$(openssl rand -hex 4)"
CONTAINER_NAME="images"
BICEP_FILE="$(dirname "$0")/blob-storage.bicep"

echo "====================================================="
echo " Phase 1: Azure Blob Storage セットアップ"
echo "====================================================="

# -------------------------------------------------------
# 1. Azure CLI ログイン確認
# -------------------------------------------------------
echo ""
echo "[1/5] Azure ログイン確認..."
if ! az account show &>/dev/null; then
  echo "Azure にログインしていません。ブラウザでログインします..."
  az login
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "  サブスクリプション ID : ${SUBSCRIPTION_ID}"
echo "  テナント ID          : ${TENANT_ID}"

# -------------------------------------------------------
# 2. リソースグループ作成
# -------------------------------------------------------
echo ""
echo "[2/5] リソースグループ作成..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output table

echo "  リソースグループ : ${RESOURCE_GROUP} (${LOCATION})"

# -------------------------------------------------------
# 3. Bicep テンプレートで Blob Storage デプロイ
# -------------------------------------------------------
echo ""
echo "[3/5] Bicep テンプレートで Blob Storage をデプロイ..."
DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${BICEP_FILE}" \
  --parameters storageAccountName="${STORAGE_ACCOUNT_NAME}" \
               containerName="${CONTAINER_NAME}" \
               enablePublicAccess=true \
  --query "properties.outputs" \
  --output json)

STORAGE_ACCOUNT_NAME_ACTUAL=$(echo "${DEPLOY_OUTPUT}" | jq -r '.storageAccountName.value')
IMAGES_BASE_URL=$(echo "${DEPLOY_OUTPUT}" | jq -r '.imagesBaseUrl.value')

echo "  ストレージアカウント : ${STORAGE_ACCOUNT_NAME_ACTUAL}"
echo "  画像ベースURL        : ${IMAGES_BASE_URL}"

# -------------------------------------------------------
# 4. Microsoft Graph API でストレージアカウントの確認
#    （Azure AD / Entra ID のリソース情報を Graph API で取得）
# -------------------------------------------------------
echo ""
echo "[4/5] Microsoft Graph API でサブスクリプション情報を確認..."

# Graph API 用アクセストークン取得
GRAPH_TOKEN=$(az account get-access-token \
  --resource "https://graph.microsoft.com" \
  --query accessToken \
  --output tsv)

# テナント情報を Graph API で取得
TENANT_INFO=$(curl -s -X GET \
  "https://graph.microsoft.com/v1.0/organization" \
  -H "Authorization: Bearer ${GRAPH_TOKEN}" \
  -H "Content-Type: application/json")

TENANT_DISPLAY_NAME=$(echo "${TENANT_INFO}" | jq -r '.value[0].displayName')
echo "  テナント名 : ${TENANT_DISPLAY_NAME}"

# -------------------------------------------------------
# 5. 設定情報をファイルに保存（.env.local の雛形）
# -------------------------------------------------------
echo ""
echo "[5/5] 設定情報を .env.local に保存..."
ENV_FILE="$(dirname "$0")/../../.env.local.example"
cat > "${ENV_FILE}" <<EOF
# Azure Blob Storage 設定
# このファイルを .env.local にコピーして使用してください
NEXT_PUBLIC_BLOB_BASE_URL=${IMAGES_BASE_URL}
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME_ACTUAL}
AZURE_STORAGE_CONTAINER_NAME=${CONTAINER_NAME}

# Azure 設定
AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
AZURE_TENANT_ID=${TENANT_ID}
AZURE_RESOURCE_GROUP=${RESOURCE_GROUP}
EOF

echo "  設定ファイル : ${ENV_FILE}"

echo ""
echo "====================================================="
echo " Phase 1 完了！"
echo "====================================================="
echo ""
echo "次のステップ:"
echo "  1. .env.local.example を .env.local にコピー"
echo "  2. src/posts/ に MDX ブログ記事を追加"
echo "  3. Phase 3-4 の IaC で Static Web Apps をデプロイ"
echo ""
