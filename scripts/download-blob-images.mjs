#!/usr/bin/env node
/**
 * GitHub Actions ビルド時に Azure Blob Storage から画像を取得するスクリプト
 *
 * 認証: Entra ID App Registration（ClientSecretCredential）
 * 必要な環境変数（GitHub Actions Secrets）:
 *   - AZURE_TENANT_ID
 *   - AZURE_CLIENT_ID
 *   - AZURE_CLIENT_SECRET
 *   - AZURE_STORAGE_ACCOUNT_NAME
 *   - AZURE_STORAGE_CONTAINER_NAME
 */

import { BlobServiceClient } from "@azure/storage-blob";
import { ClientSecretCredential } from "@azure/identity";

// GitHub Actions で別ステップ実行済みの場合はスキップ
if (process.env.SKIP_BLOB_DOWNLOAD === "true") {
  console.log("[download-blob-images] SKIP_BLOB_DOWNLOAD=true のためスキップします");
  process.exit(0);
}
import { createWriteStream, mkdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { pipeline } from "stream/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, "../public/blog-images");
const PUBLIC_DIR = join(__dirname, "../public");

// -------------------------------------------------------
// 環境変数の確認
// -------------------------------------------------------
const requiredEnvVars = [
  "AZURE_TENANT_ID",
  "AZURE_CLIENT_ID",
  "AZURE_CLIENT_SECRET",
  "AZURE_STORAGE_ACCOUNT_NAME",
  "AZURE_STORAGE_CONTAINER_NAME",
];

const missingVars = requiredEnvVars.filter((v) => !process.env[v]);
if (missingVars.length > 0) {
  console.warn(
    `[download-blob-images] 以下の環境変数が未設定です: ${missingVars.join(", ")}`
  );
  console.warn(
    "[download-blob-images] Blob Storage からの画像ダウンロードをスキップします"
  );
  process.exit(0); // ローカル開発時はスキップ（エラーにしない）
}

const {
  AZURE_TENANT_ID,
  AZURE_CLIENT_ID,
  AZURE_CLIENT_SECRET,
  AZURE_STORAGE_ACCOUNT_NAME,
  AZURE_STORAGE_CONTAINER_NAME,
} = process.env;

// -------------------------------------------------------
// Entra ID App Registration で認証（ClientSecretCredential）
// -------------------------------------------------------
console.log("[download-blob-images] Entra ID App Registration で認証中...");
const credential = new ClientSecretCredential(
  AZURE_TENANT_ID,
  AZURE_CLIENT_ID,
  AZURE_CLIENT_SECRET
);

const blobServiceClient = new BlobServiceClient(
  `https://${AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
  credential
);

const containerClient = blobServiceClient.getContainerClient(
  AZURE_STORAGE_CONTAINER_NAME
);

// -------------------------------------------------------
// 出力ディレクトリ作成
// -------------------------------------------------------
mkdirSync(OUTPUT_DIR, { recursive: true });
console.log(`[download-blob-images] 出力先: ${OUTPUT_DIR}`);

// -------------------------------------------------------
// Blob 一覧を取得してダウンロード
// -------------------------------------------------------
let downloadCount = 0;
let skipCount = 0;

console.log(
  `[download-blob-images] コンテナ "${AZURE_STORAGE_CONTAINER_NAME}" から画像を取得中...`
);

for await (const blob of containerClient.listBlobsFlat()) {
  // 画像ファイルのみ対象
  const imageExtensions = /\.(png|jpg|jpeg|gif|webp|svg|avif)$/i;
  if (!imageExtensions.test(blob.name)) {
    skipCount++;
    continue;
  }

  const outputPath = join(OUTPUT_DIR, blob.name);
  const outputDirPath = dirname(outputPath);
  mkdirSync(outputDirPath, { recursive: true });

  const blockBlobClient = containerClient.getBlockBlobClient(blob.name);
  const downloadResponse = await blockBlobClient.download();

  if (!downloadResponse.readableStreamBody) {
    console.warn(`  [スキップ] ${blob.name}: ストリームが取得できません`);
    continue;
  }

  await pipeline(downloadResponse.readableStreamBody, createWriteStream(outputPath));
  console.log(`  [ダウンロード] ${blob.name}`);
  downloadCount++;
}

console.log(
  `[download-blob-images] 完了: ${downloadCount} 件ダウンロード, ${skipCount} 件スキップ`
);

// -------------------------------------------------------
// アイコン画像を images コンテナから取得 → public/icon.jpg
// -------------------------------------------------------
console.log("[download-blob-images] images コンテナから icon.jpg を取得中...");
const iconContainerClient = blobServiceClient.getContainerClient("images");
const iconBlobClient = iconContainerClient.getBlockBlobClient("icon.jpg");
const iconDownload = await iconBlobClient.download();
if (iconDownload.readableStreamBody) {
  mkdirSync(PUBLIC_DIR, { recursive: true });
  await pipeline(iconDownload.readableStreamBody, createWriteStream(join(PUBLIC_DIR, "icon.jpg")));
  console.log("[download-blob-images] icon.jpg → public/icon.jpg ダウンロード完了");
} else {
  console.warn("[download-blob-images] icon.jpg のストリームが取得できません");
}
