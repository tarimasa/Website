import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  trailingSlash: true,
  // prebuild スクリプトが SKIP_PREBUILD=true の場合はスキップ
  // （GitHub Actions では download-blob-images.mjs を別ステップで実行するため）
  images: {
    unoptimized: true,
    // ローカル開発用: public/blog-images/ からも提供
    remotePatterns: [],
  },
};

export default nextConfig;
