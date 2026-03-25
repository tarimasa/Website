import type { Metadata } from "next";
import Link from "next/link";
import { getSortedPostsData, getAllTags } from "@/lib/posts";
import BlogCard from "@/components/BlogCard";
import Sidebar from "@/components/Sidebar";

interface Props {
  params: Promise<{ tag: string }>;
}

export function generateStaticParams() {
  const tags = getAllTags();
  return tags.map((tag) => ({ tag: encodeURIComponent(tag) }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { tag: rawTag } = await params;
  const tag = decodeURIComponent(rawTag);
  return {
    title: `${tag} の記事一覧`,
    description: `${tag} タグの記事一覧`,
  };
}

export default async function TagPage({ params }: Props) {
  const { tag: rawTag } = await params;
  const tag = decodeURIComponent(rawTag);
  const allPosts = getSortedPostsData();
  const posts = allPosts.filter((post) => post.tags.includes(tag));

  return (
    <div className="max-w-5xl mx-auto px-4 py-12">
      <div className="grid grid-cols-1 lg:grid-cols-[1fr_280px] gap-8">
        <main>
          <div className="mb-8">
            <nav className="text-sm text-slate-500 mb-2">
              <Link href="/blog" className="hover:text-slate-700 transition-colors">
                ブログ
              </Link>
              {" > "}
              <span className="text-slate-700">{tag}</span>
            </nav>
            <h1 className="text-2xl font-bold text-slate-900">
              <span className="px-3 py-1 bg-blue-50 text-blue-700 rounded-lg">{tag}</span>
              <span className="ml-2 text-slate-600 text-lg font-normal">の記事一覧</span>
            </h1>
            <p className="text-slate-500 text-sm mt-2">{posts.length} 件の記事</p>
          </div>
          {posts.length > 0 ? (
            <div className="grid gap-6">
              {posts.map((post) => (
                <BlogCard key={post.slug} post={post} />
              ))}
            </div>
          ) : (
            <p className="text-slate-500 text-center py-12">記事がありません。</p>
          )}
        </main>
        <Sidebar />
      </div>
    </div>
  );
}
