import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

const ADSENSE_CLIENT_ID = "ca-pub-9747176730475734";

export const metadata: Metadata = {
  title: {
    default: "Tarimasa tech | EntraID・ゼロトラスト・M365 技術ブログ",
    template: "%s | Tarimasa tech",
  },
  description:
    "NTT西日本セールスSEがEntraID・ゼロトラスト・M365・GIGAスクールの知見を発信する技術ブログ。",
  keywords: ["EntraID", "ゼロトラスト", "M365", "Azure", "GIGAスクール", "Microsoft"],
  authors: [{ name: "tarimasa" }],
  icons: {
    icon: "/icon.jpg",
    shortcut: "/icon.jpg",
    apple: "/icon.jpg",
  },
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://www.tarimasa.com",
    siteName: "Tarimasa tech",
  },
  // AdSense サイト所有権確認用 meta タグ
  other: {
    "google-adsense-account": ADSENSE_CLIENT_ID,
  },
};


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <head>
        {/* Google AdSense: <head> 内に配置（AdSense 審査・広告表示の要件） */}
        {ADSENSE_CLIENT_ID && (
          <script
            async
            src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_CLIENT_ID}`}
            crossOrigin="anonymous"
          />
        )}
      </head>
      <body className={`${inter.variable} font-sans min-h-screen flex flex-col`}>
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
