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
| ホスティング | Azure Static Web Apps（**Freeプラン**） | 無料・Azureの実績になる |
| DNS/WAF | Cloudflare | 無料・DDoS対策・WAF |
| ドメイン | Cloudflare Registrar | 年1,000〜2,000円 |
| CI/CD | GitHub Actions | pushで自動デプロイ |
| 画像ストレージ | Azure Blob Storage（プライベート） | ほぼ無料・Azureポートフォリオになる |
| 認証 | **Entra ID App Registration** | Graph APIで自動作成・キーレス認証の代替 |
| IaC | Bicep + **Microsoft Graph API** | Graph APIでEntra ID操作を完全自動化 |
| バージョン管理 | GitHub | ポートフォリオとして公開 |

---

## インフラ構成

```
ユーザー
　↓
Cloudflare（DNS・WAF・DDoS対策）
　↓
Azure Static Web Apps（Free・ホスティング・CDN内蔵）
　↓ ← GitHub Actions（push → 自動ビルド・デプロイ）
Next.js 14（静的サイト生成 / SSG）
　↓
MDXファイル（ブログ記事） → GitHub管理
画像ファイル → Azure Blob Storage（プライベートコンテナ）
　　　　　　　↑ ビルド時にApp Registrationの認証でダウンロード
```

---

## セキュリティ設計（ポートフォリオ要素）

### アーキテクチャ

Azure Static Web Apps **Free プラン**でも Managed Identity 相当の「キーレス認証」を実現する。
Entra ID App Registration を **Microsoft Graph API** で自動作成し、Azure ARM API で RBAC を付与する。

```
[IaC 自動構築フロー]
infra/phase1/setup.sh
　↓ Bicep: Blob Storage 作成（プライベートコンテナ）

infra/phase3-4/setup-app-registration.sh
　↓ Graph API: App Registration 自動作成
　↓ Graph API: Service Principal 作成
　↓ Graph API: クライアントシークレット発行
　↓ ARM API:   Storage Blob Data Reader ロール付与
　↓ gh CLI:    GitHub Actions シークレットに資格情報を自動登録
```

```
[ビルド時の画像取得フロー]
GitHub Actions（push トリガー）
　↓ scripts/download-blob-images.mjs 実行
　  → ClientSecretCredential（App Registration）で認証
　  → Blob Storage（プライベート）から画像をダウンロード
　  → public/blog-images/ に配置
　↓ next build → 静的エクスポート（画像込み）
　↓ Azure Static Web Apps にデプロイ
```

### 実装するセキュリティ設定

**① Entra ID App Registration（Graph API で自動作成）**
- `POST https://graph.microsoft.com/v1.0/applications` でアプリ登録
- `POST https://graph.microsoft.com/v1.0/servicePrincipals` でSP作成
- クライアントシークレット発行（GitHub Actions のみに配布）
- Managed Identity を使わずに「キーレス認証相当」を実現

**② Blob StorageのRBAC（ARM API で自動付与）**
- App Registration の SP に「Storage Blob Data Reader」ロールを付与
- 読み取り専用・最小権限の原則
- Blob Storage はパブリックアクセス無効

**③ ネットワーク・フロントエンドのセキュリティ**
- `staticwebapp.config.json` で CSP・X-Frame-Options・HSTS 等のセキュリティヘッダー
- Cloudflare WAF でボット対策・SQLi/XSS フィルタ
- GitHub Actions シークレットで資格情報を保護

### ポートフォリオとしての価値

「Microsoft Graph API で Entra ID App Registration を自動作成し、Azure ARM API で最小権限 RBAC を構成。GitHub Actions のビルドパイプライン内でキーレス認証を実現しました」

- ゼロトラスト原則（最小権限・キーレス認証）の実践
- Graph API × ARM API を組み合わせた Infrastructure as Code
- **Free プランでも本番品質のセキュリティを設計できる**ことを実証

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
- [ ] `infra/phase1/setup.sh` を実行（リソースグループ + Blob Storage 自動デプロイ）

→ 詳細手順: [`infra/phase1/README.md`](infra/phase1/README.md)

### Phase 2：Next.jsプロジェクト作成
- [ ] `src/` ディレクトリの Next.js プロジェクトをベースに開発
- [ ] MDXでブログ機能実装（`src/posts/` にMDXファイル追加）
- [ ] トップページ・ブログ一覧・記事詳細ページのカスタマイズ
- [ ] Google AdSenseコード組み込み（`src/app/layout.tsx`）

### Phase 3：Azure Static Web Appsデプロイ（IaC）
- [ ] `infra/phase3-4/setup-app-registration.sh` を実行（Graph API + ARM API）
  - Entra ID App Registration を自動作成
  - Blob Storage へのRBAC自動付与
  - GitHub Actions シークレット自動設定
- [ ] `infra/phase3-4/deploy.sh` を実行（Bicep で Static Web Apps デプロイ）
- [ ] GitHub Actions ワークフロー（`.github/workflows/`）実行確認
- [ ] カスタムドメイン設定 + CloudflareのDNSにCNAMEレコード追加
- [ ] SSL証明書自動発行確認

### Phase 4：セキュリティ設定確認
- [ ] Entra ID ポータルで App Registration を確認
- [ ] Blob Storage の RBAC ロール割り当て確認
- [ ] GitHub Actions でビルドが成功し画像が表示されることを確認

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
│   └── phase3-4/             # Static Web Apps IaC + App Registration
│       ├── main.bicep
│       ├── static-web-app.bicep
│       ├── setup-app-registration.sh  # Graph API + ARM API（メイン）
│       └── deploy.sh
├── scripts/
│   └── download-blob-images.mjs      # ビルド時 Blob 画像取得
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
| Azure Static Web Apps（**Free**） | **0円** |
| Azure Blob Storage（5GB・個人ブログ規模） | 1〜数円 |
| Cloudflare DNS/WAF | 0円 |
| GitHub（Free） | 0円 |
| ドメイン（お名前.com） | 約150円/月（年1,800円） |
| **合計** | **約150〜200円/月** |

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
