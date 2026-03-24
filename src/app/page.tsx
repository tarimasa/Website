import Link from "next/link";
import { getSortedPostsData } from "@/lib/posts";
import BlogCard from "@/components/BlogCard";

export default function Home() {
  const recentPosts = getSortedPostsData().slice(0, 3);

  return (
    <div className="max-w-4xl mx-auto px-4 py-12">
      {/* ヒーローセクション */}
      <section className="text-center mb-16">
        <div className="mb-6">
          <div className="w-24 h-24 rounded-full bg-gradient-to-br from-blue-500 to-blue-700 mx-auto flex items-center justify-center text-white text-3xl font-bold mb-4">
            T
          </div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">tarimasa</h1>
          <p className="text-lg text-slate-600">
            NTT西日本 セールスSE | EntraID / ゼロトラスト / M365 専門
          </p>
        </div>
        <p className="text-slate-700 max-w-2xl mx-auto leading-relaxed">
          教育委員会・自治体向けのゼロトラスト提案、GIGAスクール対応、M365展開を担当。
          Microsoft 転職に向けてポートフォリオと技術ブログを発信中。
        </p>
        <div className="flex justify-center gap-4 mt-6">
          <a
            href="https://github.com/tarimasa"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-700 transition-colors"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
            </svg>
            GitHub
          </a>
          <a
            href="https://x.com/tarimasa"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2 bg-black text-white rounded-lg hover:bg-slate-800 transition-colors"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
            X (Twitter)
          </a>
        </div>
      </section>

      {/* スキル・専門領域 */}
      <section className="mb-16">
        <h2 className="text-xl font-bold text-slate-900 mb-6 pb-2 border-b border-slate-200">
          専門領域
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { icon: "🔐", title: "EntraID", desc: "SSO・MFA・RBAC設計" },
            { icon: "🛡️", title: "ゼロトラスト", desc: "条件付きアクセス・ID保護" },
            { icon: "📧", title: "M365", desc: "ライセンス管理・展開" },
            { icon: "🏫", title: "GIGAスクール", desc: "教育委員会向け提案" },
          ].map((skill) => (
            <div
              key={skill.title}
              className="bg-white border border-slate-200 rounded-xl p-4 text-center hover:border-blue-300 hover:shadow-sm transition-all"
            >
              <div className="text-3xl mb-2">{skill.icon}</div>
              <div className="font-semibold text-slate-900 text-sm">{skill.title}</div>
              <div className="text-slate-500 text-xs mt-1">{skill.desc}</div>
            </div>
          ))}
        </div>
      </section>

      {/* 最新ブログ記事 */}
      <section>
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-slate-900 pb-2 border-b border-slate-200 flex-1">
            最新記事
          </h2>
          <Link
            href="/blog"
            className="ml-4 text-blue-600 hover:text-blue-800 text-sm font-medium"
          >
            すべての記事 →
          </Link>
        </div>
        {recentPosts.length > 0 ? (
          <div className="grid gap-6">
            {recentPosts.map((post) => (
              <BlogCard key={post.slug} post={post} />
            ))}
          </div>
        ) : (
          <p className="text-slate-500 text-center py-12">
            記事を準備中です。しばらくお待ちください。
          </p>
        )}
      </section>
    </div>
  );
}
