import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: {
    default: "tarimasa.dev | EntraID・ゼロトラスト・M365 技術ブログ",
    template: "%s | tarimasa.dev",
  },
  description:
    "NTT西日本セールスSEがEntraID・ゼロトラスト・M365・GIGAスクールの知見を発信する技術ブログ。Microsoft転職を目指すポートフォリオサイト。",
  keywords: ["EntraID", "ゼロトラスト", "M365", "Azure", "GIGAスクール", "Microsoft"],
  authors: [{ name: "tarimasa" }],
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://tarimasa.dev",
    siteName: "tarimasa.dev",
  },
};

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
        {/* Google AdSense（申請後にコメントアウトを解除） */}
        {/* <script
          async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXXXXXXXXX"
          crossOrigin="anonymous"
        /> */}
      </body>
    </html>
  );
}
