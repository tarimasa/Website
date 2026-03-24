#!/usr/bin/env bash
# =============================================================================
# Phase 1: Azure Blob Storage セットアップスクリプト
# 使用技術: Azure CLI + Bicep
# =============================================================================
set -euo pipefail

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
echo "[1/4] Azure ログイン確認..."
if ! az account show &>/dev/null; then
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
echo "[2/4] リソースグループ作成..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output table

# -------------------------------------------------------
# 3. Bicep テンプレートで Blob Storage デプロイ
# -------------------------------------------------------
echo ""
echo "[3/4] Bicep テンプレートで Blob Storage をデプロイ..."
DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${BICEP_FILE}" \
  --parameters storageAccountName="${STORAGE_ACCOUNT_NAME}" \
               containerName="${CONTAINER_NAME}" \
  --query "properties.outputs" \
  --output json)

STORAGE_ACCOUNT_NAME_ACTUAL=$(echo "${DEPLOY_OUTPUT}" | jq -r '.storageAccountName.value')
BLOB_ENDPOINT=$(echo "${DEPLOY_OUTPUT}" | jq -r '.storageAccountBlobEndpoint.value')
STORAGE_ACCOUNT_ID=$(echo "${DEPLOY_OUTPUT}" | jq -r '.storageAccountId.value')

echo "  ストレージアカウント : ${STORAGE_ACCOUNT_NAME_ACTUAL}"
echo "  Blob エンドポイント  : ${BLOB_ENDPOINT}"

# -------------------------------------------------------
# 4. Microsoft Graph API でテナント情報を確認
# -------------------------------------------------------
echo ""
echo "[4/4] Microsoft Graph API でテナント情報を確認..."
GRAPH_TOKEN=$(az account get-access-token \
  --resource "https://graph.microsoft.com" \
  --query accessToken \
  --output tsv)

TENANT_INFO=$(curl -s -X GET \
  "https://graph.microsoft.com/v1.0/organization" \
  -H "Authorization: Bearer ${GRAPH_TOKEN}" \
  -H "Content-Type: application/json")

TENANT_DISPLAY_NAME=$(echo "${TENANT_INFO}" | jq -r '.value[0].displayName')
echo "  テナント名 : ${TENANT_DISPLAY_NAME}"

# 設定ファイル保存
cat > "$(dirname "$0")/../../.blob-config.env" <<EOF
AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
AZURE_TENANT_ID=${TENANT_ID}
AZURE_RESOURCE_GROUP=${RESOURCE_GROUP}
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME_ACTUAL}
AZURE_STORAGE_ACCOUNT_ID=${STORAGE_ACCOUNT_ID}
AZURE_STORAGE_CONTAINER_NAME=${CONTAINER_NAME}
AZURE_BLOB_ENDPOINT=${BLOB_ENDPOINT}
EOF

echo ""
echo "====================================================="
echo " Phase 1 完了！設定を .blob-config.env に保存しました"
echo "====================================================="
echo ""
echo "次: infra/phase3-4/setup-app-registration.sh を実行してください"
