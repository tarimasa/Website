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
// アイコン画像を取得 → public/icon.jpg
// 試行順: メインコンテナ → "images" コンテナ の順で
// ファイル名: icon.jpg / icon.jpeg / icon.png / icon（拡張子なし）を試行
// -------------------------------------------------------
console.log("[download-blob-images] アイコン画像を検索中...");

// 診断: ストレージアカウントのコンテナ一覧を表示
try {
  const containerList = [];
  for await (const c of blobServiceClient.listContainers()) {
    containerList.push(c.name);
  }
  console.log(`[download-blob-images] 利用可能なコンテナ: ${containerList.join(", ")}`);
} catch (e) {
  console.warn(`[download-blob-images] コンテナ一覧の取得に失敗: ${e.message}`);
}

const iconCandidates = ["icon.jpg", "icon.jpeg", "icon.png", "icon"];
const iconContainerNames = [AZURE_STORAGE_CONTAINER_NAME, "images", "image"];

let iconFound = false;

outer: for (const containerName of iconContainerNames) {
  const iconContainer = blobServiceClient.getContainerClient(containerName);
  for (const blobName of iconCandidates) {
    try {
      const blobClient = iconContainer.getBlockBlobClient(blobName);
      const exists = await blobClient.exists();
      if (!exists) continue;

      console.log(`[download-blob-images] コンテナ "${containerName}" で "${blobName}" を発見`);
      const download = await blobClient.download();
      if (!download.readableStreamBody) continue;

      mkdirSync(PUBLIC_DIR, { recursive: true });
      await pipeline(
        download.readableStreamBody,
        createWriteStream(join(PUBLIC_DIR, "icon.jpg"))
      );
      console.log(`[download-blob-images] ${containerName}/${blobName} → public/icon.jpg ダウンロード完了`);
      iconFound = true;
      break outer;
    } catch (e) {
      console.warn(`[download-blob-images] ${containerName}/${blobName} の取得に失敗: ${e.message}`);
    }
  }
}

if (!iconFound) {
  console.warn("[download-blob-images] アイコン画像が見つかりませんでした。public/icon.jpg をスキップします");
}
