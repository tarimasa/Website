import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",  // Azure Static Web Apps 用に静的エクスポート
  trailingSlash: true,
  images: {
    unoptimized: true,  // 静的エクスポート時は画像最適化を無効化
    remotePatterns: [
      {
        protocol: "https",
        hostname: "*.blob.core.windows.net",  // Azure Blob Storage
        pathname: "/images/**",
      },
    ],
  },
};

export default nextConfig;
