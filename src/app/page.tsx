import Link from "next/link";
import { getSortedPostsData } from "@/lib/posts";
import BlogCard from "@/components/BlogCard";
import Sidebar from "@/components/Sidebar";

export default function Home() {
  const recentPosts = getSortedPostsData().slice(0, 3);

  return (
    <div className="max-w-5xl mx-auto px-4 py-12">
      <div className="grid grid-cols-1 lg:grid-cols-[1fr_280px] gap-8">
        <main>
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
        </main>
        <Sidebar />
      </div>
    </div>
  );
}
