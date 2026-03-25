import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Script from "next/script";
import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: {
    default: "Tarimasa tech | EntraID・ゼロトラスト・M365 技術ブログ",
    template: "%s | Tarimasa tech",
  },
  description:
    "NTT西日本セールスSEがEntraID・ゼロトラスト・M365・GIGAスクールの知見を発信する技術ブログ。Microsoft転職を目指すポートフォリオサイト。",
  keywords: ["EntraID", "ゼロトラスト", "M365", "Azure", "GIGAスクール", "Microsoft"],
  authors: [{ name: "tarimasa" }],
  icons: {
    icon: "https://picture0808.blob.core.windows.net/images/icon.jpg",
    shortcut: "https://picture0808.blob.core.windows.net/images/icon.jpg",
    apple: "https://picture0808.blob.core.windows.net/images/icon.jpg",
  },
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://tarimasa.dev",
    siteName: "Tarimasa tech",
  },
};

// AdSense パブリッシャーID（AdSense 審査通過後に設定）
// 設定方法: GitHub リポジトリの Settings > Secrets > NEXT_PUBLIC_ADSENSE_CLIENT_ID
// 値の例: ca-pub-XXXXXXXXXXXXXXXX
const ADSENSE_CLIENT_ID = process.env.NEXT_PUBLIC_ADSENSE_CLIENT_ID ?? "";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body className={`${inter.variable} font-sans min-h-screen flex flex-col`}>
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />

        {/* Google AdSense: NEXT_PUBLIC_ADSENSE_CLIENT_ID が設定されている場合のみ読み込む */}
        {ADSENSE_CLIENT_ID && (
          <Script
            async
            src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_CLIENT_ID}`}
            crossOrigin="anonymous"
            strategy="afterInteractive"
          />
        )}
      </body>
    </html>
  );
}
