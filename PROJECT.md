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
| フレームワーク | Next.js | Microsoftポートフォリオとして説得力あり |
| ホスティング | Azure Static Web Apps（Freeプラン） | 無料・商用利用可・Azureの実績になる |
| DNS | Cloudflare | 無料・CDN・DDoS対策込み |
| ドメイン | お名前.com or Cloudflare Registrar | 年1,000〜2,000円 |
| CI/CD | GitHub Actions | pushで自動デプロイ |
| 画像ストレージ | Azure Blob Storage | ほぼ無料・Azureポートフォリオになる |
| バージョン管理 | GitHub | ポートフォリオとして公開 |

---

## インフラ構成

```
ユーザー
　↓
Cloudflare（DNS・CDN・DDoS対策）
　↓
Azure Static Web Apps（ホスティング）
　↓
Next.js（静的サイト生成）
　↓
MDファイル（ブログ記事）→ GitHub管理
画像ファイル → Azure Blob Storage（マネージドID経由）
```

---

## セキュリティ設計（ポートフォリオ要素）

### 構成概要

Azure Static Web Apps と Azure Blob Storage 間のアクセスをEntra IDで制御する。

```
ユーザー
　↓
Azure Static Web Apps
　↓（マネージドID経由・キーレス認証）
Azure Blob Storage
　↑
　Entra ID（RBAC・アクセス制御）
```

### 実装するセキュリティ設定

**① マネージドID（Managed Identity）**
- Static Web AppsにシステムマネージドIDを付与
- Blob StorageへのアクセスにSASキーや接続文字列を使わない
- キーレス認証でセキュアな連携を実現

**② Blob StorageのRBAC設定**
- マネージドIDに「Storage Blob Data Reader」ロールを付与
- パブリックアクセスを無効化（匿名アクセス禁止）
- 画像はStatic Web Apps経由でのみ配信

**③ ネットワークアクセス制御**
- Blob StorageのファイアウォールでAzure Static Web Appsからのアクセスのみ許可
- パブリックネットワークアクセスを制限

### ポートフォリオとしての価値

「Azure Static Web Apps + Blob Storage + Entra ID（マネージドID）でキーレス認証を実装しました」はMicrosoft営業の面接で以下の文脈で語れる：

- ゼロトラスト原則（最小権限・キーレス認証）の実践
- EntraID × AzureリソースのRBAC設計経験
- Azureセキュリティベストプラクティスの理解

---

## サイト構成

- **トップページ**：自己紹介・プロフィール
- **技術ブログ**：MDファイルベースの記事（EntraID・ゼロトラスト・M365・GIGAスクール等）
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

### Phase 1：環境準備
- [ ] 個人Azureアカウント作成（無料枠 $200クレジット）
- [ ] GitHubアカウント確認・リポジトリ作成
- [ ] ドメイン取得（お名前.com or Cloudflare Registrar）
- [ ] Cloudflareアカウント作成・DNSをCloudflareに向ける
- [ ] Azure Blob Storageアカウント作成（Standard LRS・東日本リージョン）
- [ ] Blobコンテナ作成・パブリックアクセス無効化

### Phase 2：Next.jsプロジェクト作成
- [ ] `npx create-next-app`でプロジェクト初期化
- [ ] MDXまたはContentlayerでブログ機能実装
- [ ] トップページ作成（自己紹介・プロフィール）
- [ ] ブログ一覧・詳細ページ作成
- [ ] GitHub・Twitter/Xリンク設置
- [ ] Google AdSenseコード組み込み

### Phase 3：Azure Static Web Appsデプロイ
- [ ] Azureポータルで Static Web Apps リソース作成（Freeプラン）
- [ ] GitHubリポジトリと連携設定
- [ ] GitHub Actionsワークフロー自動生成確認
- [ ] カスタムドメイン設定（Azureポータル）
- [ ] CloudflareのDNSにCNAMEレコード追加
- [ ] SSL証明書自動発行確認

### Phase 4：セキュリティ設定（ポートフォリオ）
- [ ] Static Web AppsにシステムマネージドID有効化
- [ ] Blob StorageにRBACロール付与（Storage Blob Data Reader）
- [ ] Blob Storageファイアウォール設定（Static Web Appsのみ許可）
- [ ] パブリックネットワークアクセス無効化
- [ ] 動作確認（画像が正常に表示されるか）

### Phase 5：動作確認・公開
- [ ] カスタムドメインでアクセス確認
- [ ] ブログ記事を1本投稿してデプロイ確認
- [ ] Google AdSense申請
- [ ] Google Analytics設置（アクセス解析）

### Phase 6：ブログ運用
- [ ] 記事をMDファイルで作成しGitHubにpush
- [ ] GitHub Actionsが自動でビルド・デプロイ
- [ ] 定期的に記事を追加

---

## コスト試算

| 項目 | 月額 |
|------|------|
| Azure Static Web Apps（Free） | 0円 |
| Azure Blob Storage（5GB無料枠・個人ブログ規模） | 1〜数円 |
| Cloudflare DNS | 0円 |
| GitHub（Free） | 0円 |
| ドメイン | 約150円/月（年1,800円） |
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
