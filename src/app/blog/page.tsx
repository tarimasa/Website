import type { Metadata } from "next";
import { getSortedPostsData } from "@/lib/posts";
import BlogCard from "@/components/BlogCard";

export const metadata: Metadata = {
  title: "技術ブログ",
  description: "EntraID・ゼロトラスト・M365・GIGAスクールに関する技術記事の一覧",
};

export default function BlogPage() {
  const posts = getSortedPostsData();

  return (
    <div className="max-w-4xl mx-auto px-4 py-12">
      <h1 className="text-3xl font-bold text-slate-900 mb-2">技術ブログ</h1>
      <p className="text-slate-600 mb-8">
        EntraID・ゼロトラスト・M365・GIGAスクールに関する知見を発信しています。
      </p>

      {posts.length > 0 ? (
        <div className="grid gap-6">
          {posts.map((post) => (
            <BlogCard key={post.slug} post={post} />
          ))}
        </div>
      ) : (
        <div className="text-center py-20 text-slate-500">
          <p className="text-xl mb-2">記事を準備中です</p>
          <p className="text-sm">しばらくお待ちください。</p>
        </div>
      )}
    </div>
  );
}
