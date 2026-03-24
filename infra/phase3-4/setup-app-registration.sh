#!/usr/bin/env bash
# =============================================================================
# Phase 3-4: Entra ID App Registration 自動構築スクリプト
#
# 使用 API:
#   - Microsoft Graph API: App Registration・Service Principal・シークレット作成
#   - Azure ARM API: Storage Blob Data Reader RBAC ロール付与
#   - GitHub CLI (gh): Actions シークレット自動設定
#
# 前提条件:
#   - az CLI でログイン済み
#   - gh CLI でログイン済み（gh auth login）
#   - Phase 1 の setup.sh 実行済み（.blob-config.env が存在する）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="${SCRIPT_DIR}/../../.blob-config.env"
APP_NAME="portfolio-website-build"
GITHUB_REPO="tarimasa/Website"
# シークレットの有効期限（2年後）
SECRET_EXPIRY="2028-03-24T00:00:00Z"

echo "====================================================="
echo " Phase 3-4: Entra ID App Registration 構築"
echo " （Microsoft Graph API + Azure ARM API）"
echo "====================================================="

# -------------------------------------------------------
# 設定ファイル読み込み
# -------------------------------------------------------
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "エラー: .blob-config.env が見つかりません。先に Phase 1 を実行してください。"
  exit 1
fi
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

echo "  ストレージアカウント : ${AZURE_STORAGE_ACCOUNT_NAME}"
echo "  リソースグループ     : ${AZURE_RESOURCE_GROUP}"

# -------------------------------------------------------
# 1. アクセストークン取得（Graph API 用・ARM API 用）
# -------------------------------------------------------
echo ""
echo "[1/6] アクセストークンを取得..."
GRAPH_TOKEN=$(az account get-access-token \
  --resource "https://graph.microsoft.com" \
  --query accessToken \
  --output tsv)

ARM_TOKEN=$(az account get-access-token \
  --resource "https://management.azure.com" \
  --query accessToken \
  --output tsv)

GRAPH_HEADERS=(-H "Authorization: Bearer ${GRAPH_TOKEN}" -H "Content-Type: application/json")
ARM_HEADERS=(-H "Authorization: Bearer ${ARM_TOKEN}" -H "Content-Type: application/json")

# -------------------------------------------------------
# 2. Graph API: 既存の App Registration を確認・作成
# -------------------------------------------------------
echo ""
echo "[2/6] Graph API: App Registration を確認・作成..."
echo "  エンドポイント: POST https://graph.microsoft.com/v1.0/applications"

# 既存の App Registration を検索
EXISTING_APP=$(curl -s -X GET \
  "https://graph.microsoft.com/v1.0/applications?\$filter=displayName+eq+'${APP_NAME}'&\$select=id,appId,displayName" \
  "${GRAPH_HEADERS[@]}")

EXISTING_COUNT=$(echo "${EXISTING_APP}" | jq -r '.value | length')

if [[ "${EXISTING_COUNT}" -gt 0 ]]; then
  APP_OBJECT_ID=$(echo "${EXISTING_APP}" | jq -r '.value[0].id')
  APP_CLIENT_ID=$(echo "${EXISTING_APP}" | jq -r '.value[0].appId')
  echo "  既存の App Registration を使用: ${APP_NAME} (${APP_CLIENT_ID})"
else
  # 新規作成
  APP_RESULT=$(curl -s -X POST \
    "https://graph.microsoft.com/v1.0/applications" \
    "${GRAPH_HEADERS[@]}" \
    -d "{
      \"displayName\": \"${APP_NAME}\",
      \"signInAudience\": \"AzureADMyOrg\",
      \"description\": \"GitHub Actions build agent: reads images from Blob Storage for portfolio website CI/CD\"
    }")

  APP_OBJECT_ID=$(echo "${APP_RESULT}" | jq -r '.id')
  APP_CLIENT_ID=$(echo "${APP_RESULT}" | jq -r '.appId')

  if [[ "${APP_OBJECT_ID}" == "null" || -z "${APP_OBJECT_ID}" ]]; then
    echo "エラー: App Registration の作成に失敗しました"
    echo "${APP_RESULT}" | jq .
    exit 1
  fi
  echo "  App Registration 作成完了: ${APP_NAME}"
fi

echo "  App Object ID : ${APP_OBJECT_ID}"
echo "  App Client ID : ${APP_CLIENT_ID}"

# -------------------------------------------------------
# 3. Graph API: Service Principal を確認・作成
# -------------------------------------------------------
echo ""
echo "[3/6] Graph API: Service Principal を確認・作成..."
echo "  エンドポイント: POST https://graph.microsoft.com/v1.0/servicePrincipals"

EXISTING_SP=$(curl -s -X GET \
  "https://graph.microsoft.com/v1.0/servicePrincipals?\$filter=appId+eq+'${APP_CLIENT_ID}'&\$select=id,displayName,appId" \
  "${GRAPH_HEADERS[@]}")

EXISTING_SP_COUNT=$(echo "${EXISTING_SP}" | jq -r '.value | length')

if [[ "${EXISTING_SP_COUNT}" -gt 0 ]]; then
  SP_OBJECT_ID=$(echo "${EXISTING_SP}" | jq -r '.value[0].id')
  echo "  既存の Service Principal を使用: ${SP_OBJECT_ID}"
else
  SP_RESULT=$(curl -s -X POST \
    "https://graph.microsoft.com/v1.0/servicePrincipals" \
    "${GRAPH_HEADERS[@]}" \
    -d "{\"appId\": \"${APP_CLIENT_ID}\"}")

  SP_OBJECT_ID=$(echo "${SP_RESULT}" | jq -r '.id')

  if [[ "${SP_OBJECT_ID}" == "null" || -z "${SP_OBJECT_ID}" ]]; then
    echo "エラー: Service Principal の作成に失敗しました"
    echo "${SP_RESULT}" | jq .
    exit 1
  fi
  echo "  Service Principal 作成完了: ${SP_OBJECT_ID}"
fi

# -------------------------------------------------------
# 4. Graph API: クライアントシークレット発行
# -------------------------------------------------------
echo ""
echo "[4/6] Graph API: クライアントシークレットを発行..."
echo "  エンドポイント: POST https://graph.microsoft.com/v1.0/applications/${APP_OBJECT_ID}/addPassword"

SECRET_RESULT=$(curl -s -X POST \
  "https://graph.microsoft.com/v1.0/applications/${APP_OBJECT_ID}/addPassword" \
  "${GRAPH_HEADERS[@]}" \
  -d "{
    \"passwordCredential\": {
      \"displayName\": \"GitHub Actions CI/CD - $(date +%Y-%m-%d)\",
      \"endDateTime\": \"${SECRET_EXPIRY}\"
    }
  }")

CLIENT_SECRET=$(echo "${SECRET_RESULT}" | jq -r '.secretText')

if [[ "${CLIENT_SECRET}" == "null" || -z "${CLIENT_SECRET}" ]]; then
  echo "エラー: クライアントシークレットの発行に失敗しました"
  echo "${SECRET_RESULT}" | jq .
  exit 1
fi

echo "  クライアントシークレット発行完了（有効期限: ${SECRET_EXPIRY}）"

# -------------------------------------------------------
# 5. ARM API: Storage Blob Data Reader ロール付与
# -------------------------------------------------------
echo ""
echo "[5/6] ARM API: Storage Blob Data Reader ロールを付与..."

STORAGE_BLOB_DATA_READER_ROLE_ID="2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
ROLE_ASSIGNMENT_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen | tr '[:upper:]' '[:lower:]')

# 既存のロール割り当てを確認
EXISTING_ROLE=$(curl -s -X GET \
  "https://management.azure.com${AZURE_STORAGE_ACCOUNT_ID}/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01&\$filter=principalId+eq+'${SP_OBJECT_ID}'" \
  "${ARM_HEADERS[@]}")

EXISTING_ROLE_COUNT=$(echo "${EXISTING_ROLE}" | jq -r '.value | length')

if [[ "${EXISTING_ROLE_COUNT}" -gt 0 ]]; then
  echo "  ロール割り当ては既に存在します（スキップ）"
else
  ROLE_RESULT=$(curl -s -X PUT \
    "https://management.azure.com${AZURE_STORAGE_ACCOUNT_ID}/providers/Microsoft.Authorization/roleAssignments/${ROLE_ASSIGNMENT_ID}?api-version=2022-04-01" \
    "${ARM_HEADERS[@]}" \
    -d "{
      \"properties\": {
        \"roleDefinitionId\": \"/subscriptions/${AZURE_SUBSCRIPTION_ID}/providers/Microsoft.Authorization/roleDefinitions/${STORAGE_BLOB_DATA_READER_ROLE_ID}\",
        \"principalId\": \"${SP_OBJECT_ID}\",
        \"principalType\": \"ServicePrincipal\",
        \"description\": \"Portfolio: App Registration (${APP_NAME}) -> Storage Blob Data Reader (read-only)\"
      }
    }")

  ROLE_ID=$(echo "${ROLE_RESULT}" | jq -r '.id')
  if [[ "${ROLE_ID}" == "null" || -z "${ROLE_ID}" ]]; then
    echo "エラー: ロール割り当てに失敗しました"
    echo "${ROLE_RESULT}" | jq .
    exit 1
  fi
  echo "  Storage Blob Data Reader ロール付与完了"
  echo "  ロール割り当て ID: ${ROLE_ID}"
fi

# -------------------------------------------------------
# 6. GitHub Actions シークレットに自動登録
# -------------------------------------------------------
echo ""
echo "[6/6] GitHub Actions シークレットを設定..."

if command -v gh &>/dev/null; then
  echo "${AZURE_TENANT_ID}"           | gh secret set AZURE_TENANT_ID           --repo "${GITHUB_REPO}"
  echo "${APP_CLIENT_ID}"             | gh secret set AZURE_CLIENT_ID            --repo "${GITHUB_REPO}"
  echo "${CLIENT_SECRET}"             | gh secret set AZURE_CLIENT_SECRET        --repo "${GITHUB_REPO}"
  echo "${AZURE_STORAGE_ACCOUNT_NAME}" | gh secret set AZURE_STORAGE_ACCOUNT_NAME --repo "${GITHUB_REPO}"
  echo "${AZURE_STORAGE_CONTAINER_NAME}" | gh secret set AZURE_STORAGE_CONTAINER_NAME --repo "${GITHUB_REPO}"
  echo "  GitHub Secrets 設定完了（5件）"
else
  echo "  gh CLI が見つかりません。以下を GitHub > Settings > Secrets に手動設定してください:"
  echo "    AZURE_TENANT_ID             = ${AZURE_TENANT_ID}"
  echo "    AZURE_CLIENT_ID             = ${APP_CLIENT_ID}"
  echo "    AZURE_CLIENT_SECRET         = ${CLIENT_SECRET}"
  echo "    AZURE_STORAGE_ACCOUNT_NAME  = ${AZURE_STORAGE_ACCOUNT_NAME}"
  echo "    AZURE_STORAGE_CONTAINER_NAME= ${AZURE_STORAGE_CONTAINER_NAME}"
fi

echo ""
echo "====================================================="
echo " Phase 3-4 完了！"
echo "====================================================="
echo ""
echo "設定されたリソース:"
echo "  App Registration : ${APP_NAME} (Client ID: ${APP_CLIENT_ID})"
echo "  Service Principal: ${SP_OBJECT_ID}"
echo "  RBAC ロール      : Storage Blob Data Reader"
echo "  対象スコープ     : ${AZURE_STORAGE_ACCOUNT_NAME}"
echo ""
echo "次: infra/phase3-4/deploy.sh を実行して Static Web Apps をデプロイしてください"
