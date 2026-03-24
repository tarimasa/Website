# Phase 1: Azure Blob Storage セットアップ手順

## 前提条件

- Azure CLI がインストールされていること
  - インストール: https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli
- Azure サブスクリプションがあること（無料試用版可）
- jq がインストールされていること（JSON パース用）
  - Ubuntu/WSL: `sudo apt-get install jq`
  - macOS: `brew install jq`

## 手順

### 1. Azure CLI ログイン

```bash
az login
```

ブラウザが開きます。Microsoft アカウントでログインしてください。

### 2. セットアップスクリプト実行

```bash
cd infra/phase1
chmod +x setup.sh
./setup.sh
```

スクリプトが以下を自動実行します：
1. Azure ログイン確認
2. リソースグループ `rg-portfolio` 作成（japaneast）
3. Bicep テンプレートで Blob Storage デプロイ
4. Microsoft Graph API でテナント情報確認
5. `.env.local.example` ファイル生成

### 3. 環境変数設定

```bash
cp .env.local.example ../../.env.local
```

### 4. 動作確認

```bash
# ストレージアカウントの確認
az storage account list --resource-group rg-portfolio --output table

# コンテナの確認
az storage container list \
  --account-name <your-storage-account-name> \
  --output table

# テスト画像のアップロード
az storage blob upload \
  --account-name <your-storage-account-name> \
  --container-name images \
  --name test.txt \
  --data "Hello Azure Blob Storage!" \
  --overwrite
```

## Bicep テンプレートの内容

`blob-storage.bicep` では以下を作成します：

| リソース | 設定 |
|---------|------|
| Storage Account | Standard LRS, TLS 1.2以上, HTTPS のみ |
| Blob Service | 削除保護7日間, CORS設定（画像取得用） |
| images コンテナ | publicAccess: Blob（画像の公開URL配信用） |

## Microsoft Graph API の使用箇所

Phase 1 では Graph API を使ってテナント情報を取得します。
Phase 4 では Managed Identity の Service Principal を Graph API で検索し、RBAC 割り当てを行います。

```bash
# Graph API でテナント情報取得（setup.sh 内で実行）
GET https://graph.microsoft.com/v1.0/organization
Authorization: Bearer {token}
```

## よくある問題

### ストレージアカウント名が重複している

ストレージアカウント名はグローバルで一意である必要があります。
`setup.sh` ではランダムなサフィックスを付与しますが、エラーが出た場合は再実行してください。

### リソースグループがすでに存在する

既存のリソースグループがある場合でも、`az group create` は冪等性があるため安全に実行できます。
