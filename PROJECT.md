# 個人Webサイト構築プロジェクト

## プロジェクト概要

NTT西日本のセールスSE（ゼロトラスト・M365・EntraID専門）が、Microsoft転職を目指すためのポートフォリオ兼技術ブログサイトを構築する。

### 目的
- Microsoft営業職への転職ポートフォリオとして活用
- 技術ブログによる知識発信（EntraID・ゼロトラスト・M365・GIGAスクール関連）
- Google AdSenseによる広告収益（月1万円目標）
- Azureを使った構築実績をポートフォリオに含める

---

## 技術スタック

| 役割 | 採用技術 | 理由 |
|------|---------|------|
| フレームワーク | Next.js 14（App Router） | Microsoftポートフォリオとして説得力あり |
| ホスティング | Azure Static Web Apps（Standardプラン） | Managed Identity対応・Azureの実績になる |
| DNS | Cloudflare | 無料・DDoS対策・WAF |
| CDN | Azure Static Web Apps 内蔵CDN | CloudflareはDNS/WAF専用、CDNはAzure側で完結 |
| ドメイン | Cloudflare Registrar | 年1,000〜2,000円 |
| CI/CD | GitHub Actions | pushで自動デプロイ |
| 画像ストレージ | Azure Blob Storage | ほぼ無料・Azureポートフォリオになる |
| IaC | Bicep + Microsoft Graph API | ARM テンプレートより可読性が高く、Graph API でEntra ID操作を自動化 |
| バージョン管理 | GitHub | ポートフォリオとして公開 |

---

## インフラ構成

```
ユーザー
　↓
Cloudflare（DNS・WAF・DDoS対策）
　↓
Azure Static Web Apps（ホスティング・CDN）
　↓ ← GitHub Actions（push → 自動ビルド・デプロイ）
Next.js 14（静的サイト生成 / SSG）
　↓
MDファイル（ブログ記事） → GitHub管理
画像ファイル → Azure Blob Storage（公開コンテナ）
```

---

## セキュリティ設計（ポートフォリオ要素）

### 構成概要

Azure Static Web Apps と Azure Blob Storage 間のアクセスをEntra IDで制御する。
IaC（Bicep）と Microsoft Graph API を組み合わせて、完全自動化されたセキュア構成を実現する。

```
[IaC 自動構築フロー]
Bicep デプロイ
　↓ Azure Static Web Apps作成（Managed Identity有効）
　↓ Azure Blob Storage作成（パブリックアクセス無効）
　↓
PowerShell + Microsoft Graph API
　↓ Managed Identity の Service Principal ID を取得
　↓ Azure ARM API で Storage Blob Data Reader ロール付与
　↓ Blob Storage ネットワーク制限設定
```

```
[画像配信フロー（将来拡張）]
ユーザー → Static Web Apps API（Azure Functions）
　↓ Managed Identity でトークン取得
　↓ Blob Storage から画像取得・プロキシ配信

[現フェーズ]
ユーザー → Blob Storage 公開URL
（ポートフォリオ用にMIによるプロキシ実装は Phase 5 以降）
```

### 実装するセキュリティ設定

**① マネージドID（Managed Identity）**
- Static Web AppsにシステムマネージドIDを付与（Standardプラン必須）
- Blob StorageへのアクセスにSASキーや接続文字列を使わない
- Microsoft Graph API で Managed Identity の Service Principal を検索・確認

**② Blob StorageのRBAC設定**
- Azure ARM API でマネージドIDに「Storage Blob Data Reader」ロールを付与
- パブリックアクセスを無効化（画像コンテナのみ公開設定）
- RBAC割り当ては Bicep または PowerShell + ARM REST API で自動化

**③ ネットワークアクセス制御**
- Blob StorageのファイアウォールでAzureサービスからのアクセスを許可
- パブリックネットワークアクセスは制限（画像コンテナのみ例外）

### ポートフォリオとしての価値

「Azure Static Web Apps + Blob Storage + Entra ID（マネージドID）+ Microsoft Graph API でキーレス認証を自動構築しました」はMicrosoft営業の面接で以下の文脈で語れる：

- ゼロトラスト原則（最小権限・キーレス認証）の実践
- EntraID × AzureリソースのRBAC設計経験
- Bicep + Graph API を組み合わせたInfrastructure as Code
- Azureセキュリティベストプラクティスの理解

---

## サイト構成

- **トップページ**：自己紹介・プロフィール
- **技術ブログ**：MDXファイルベースの記事（EntraID・ゼロトラスト・M365・GIGAスクール等）
- **GitHubリンク**：ポートフォリオリポジトリへのリンク
- **Twitter/Xリンク**：SNSへのリンク
- **Google AdSense**：広告掲載（収益化）

---

## ブログ想定テーマ

- 教育委員会へのゼロトラスト提案経験
- GIGAスクール環境でのEntraID構成
- M365ライセンス整理・教育委員会向け説明方法
- EntraID × 各種SaaSのCSV連携ノウハウ
- 自然言語でM365テナントを自動構築するツール（Graph API活用）

---

## 作業工程

### Phase 1：環境準備 + Azure Blob Storage構築（IaC）
- [ ] 個人Azureアカウント作成（無料枠 $200クレジット）
- [ ] GitHubアカウント確認・このリポジトリをfork or clone
- [ ] ドメイン取得（Cloudflare Registrar）
- [ ] Cloudflareアカウント作成・DNSをCloudflareに向ける
- [ ] Azure CLI インストール・ログイン（`az login`）
- [ ] リソースグループ作成（`az group create`）
- [ ] `infra/phase1/` の Bicep テンプレートで Blob Storage 自動デプロイ
- [ ] `infra/phase1/setup.sh` を実行して初期設定完了

→ 詳細手順: [`infra/phase1/README.md`](infra/phase1/README.md)

### Phase 2：Next.jsプロジェクト作成
- [ ] `src/` ディレクトリの Next.js プロジェクトをベースに開発
- [ ] MDXでブログ機能実装（`src/posts/` にMDXファイル追加）
- [ ] トップページ作成（自己紹介・プロフィール）
- [ ] ブログ一覧・詳細ページ確認・カスタマイズ
- [ ] GitHub・Twitter/Xリンク設置
- [ ] Google AdSenseコード組み込み（`src/app/layout.tsx`）

### Phase 3：Azure Static Web Appsデプロイ（IaC）
- [ ] `infra/phase3-4/` の Bicep テンプレートで Static Web Apps 自動デプロイ
- [ ] GitHub リポジトリと連携（デプロイトークンをGitHub Secretsに設定）
- [ ] GitHub Actions ワークフロー（`.github/workflows/`）確認・実行
- [ ] カスタムドメイン設定（Bicep または Azureポータル）
- [ ] CloudflareのDNSにCNAMEレコード追加
- [ ] SSL証明書自動発行確認

### Phase 4：セキュリティ設定（Managed Identity + Graph API）
- [ ] `infra/phase3-4/setup-rbac.ps1` を実行（Graph API + ARM API）
- [ ] Graph API で Managed Identity の Service Principal ID を取得・確認
- [ ] Azure ARM API で Storage Blob Data Reader ロール付与
- [ ] Blob Storageファイアウォール設定
- [ ] 動作確認（画像が正常に表示されるか）

### Phase 5：動作確認・公開
- [ ] カスタムドメインでアクセス確認
- [ ] ブログ記事を1本投稿してデプロイ確認
- [ ] Google AdSense申請
- [ ] Google Analytics設置（アクセス解析）

### Phase 6：ブログ運用
- [ ] 記事をMDXファイルで作成しGitHubにpush
- [ ] GitHub Actionsが自動でビルド・デプロイ
- [ ] 定期的に記事を追加

---

## ディレクトリ構成

```
Website/
├── infra/
│   ├── phase1/               # Blob Storage IaC
│   │   ├── blob-storage.bicep
│   │   ├── setup.sh
│   │   └── README.md
│   └── phase3-4/             # Static Web Apps IaC + セキュリティ設定
│       ├── main.bicep
│       ├── static-web-app.bicep
│       ├── setup-rbac.ps1    # Graph API + ARM API
│       └── deploy.sh
├── src/                      # Next.js アプリ
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── posts/                # MDXブログ記事
├── .github/
│   └── workflows/
│       └── azure-static-web-apps.yml
├── staticwebapp.config.json
├── next.config.ts
├── package.json
└── PROJECT.md
```

---

## コスト試算

| 項目 | 月額 |
|------|------|
| Azure Static Web Apps（Standard） | 約1,350円（$9） |
| Azure Blob Storage（5GB・個人ブログ規模） | 1〜数円 |
| Cloudflare DNS/WAF | 0円 |
| GitHub（Free） | 0円 |
| ドメイン（Cloudflare Registrar） | 約150円/月（年1,800円） |
| **合計** | **約1,500〜1,600円/月** |

> **注意**: Managed Identity を使用するには Static Web Apps Standard プランが必須（Free プランでは未対応）。
> セキュリティ設計を省略し Blob Storage を公開にする場合は Free プランで構築可（月約150〜200円）。

---

## 将来的な拡張候補

- Azure Functions + Microsoft Graph APIを使ったM365自動構築ツールをサブプロジェクトとして追加
- EntraIDからSaaS向けCSV変換ツール（教育委員会・GIGAスクール特化）
- 上記2つをポートフォリオとしてGitHubに公開しMicrosoft転職活動に活用

---

## 注意事項

- ブログ記事は会社の機密情報・顧客情報を含めない
- 業務で得た「知識・経験」を自分の言葉で書き直したものはOK
- 会社のドキュメントのコピーはNG
- 副業（AdSense収益）は就業規則上問題なし（確認済み）
