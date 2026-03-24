import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getPostData, getSortedPostsData } from "@/lib/posts";
import { format } from "date-fns";
import { ja } from "date-fns/locale";

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  const posts = getSortedPostsData();
  // 公開記事が0件のときもビルドが止まらないようダミーを返す
  if (posts.length === 0) return [{ slug: "_empty" }];
  return posts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPostData(slug);
  if (!post) return {};
  return {
    title: post.title,
    description: post.description,
    openGraph: {
      title: post.title,
      description: post.description,
      type: "article",
      publishedTime: post.date,
    },
  };
}

export default async function BlogPost({ params }: Props) {
  const { slug } = await params;
  const post = await getPostData(slug);
  if (!post) notFound();

  return (
    <article className="max-w-3xl mx-auto px-4 py-12">
      {/* ヘッダー */}
      <header className="mb-8">
        <div className="flex flex-wrap gap-2 mb-4">
          {post.tags?.map((tag: string) => (
            <span
              key={tag}
              className="px-2 py-1 bg-blue-50 text-blue-700 text-xs rounded-md font-medium"
            >
              {tag}
            </span>
          ))}
        </div>
        <h1 className="text-3xl font-bold text-slate-900 mb-4 leading-tight">
          {post.title}
        </h1>
        <div className="flex items-center gap-4 text-slate-500 text-sm">
          <time dateTime={post.date}>
            {format(new Date(post.date), "yyyy年M月d日", { locale: ja })}
          </time>
          {post.readingTime && <span>{post.readingTime} 分で読めます</span>}
        </div>
        {post.description && (
          <p className="mt-4 text-slate-600 text-lg leading-relaxed border-l-4 border-blue-400 pl-4">
            {post.description}
          </p>
        )}
      </header>

      {/* 本文（remark/rehype で変換済みの HTML を出力） */}
      <div
        className="prose prose-slate max-w-none
          prose-headings:font-bold prose-headings:text-slate-900
          prose-a:text-blue-600 hover:prose-a:text-blue-800
          prose-code:text-blue-700 prose-code:bg-slate-100 prose-code:px-1 prose-code:py-0.5 prose-code:rounded
          prose-pre:bg-slate-900
          prose-blockquote:border-blue-400 prose-blockquote:text-slate-600"
        dangerouslySetInnerHTML={{ __html: post.contentHtml }}
      />

      {/* フッター */}
      <footer className="mt-12 pt-8 border-t border-slate-200">
        <a href="/blog" className="text-blue-600 hover:text-blue-800 font-medium">
          ← 記事一覧に戻る
        </a>
      </footer>
    </article>
  );
}
