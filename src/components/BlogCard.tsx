import Link from "next/link";
import type { PostMeta } from "@/lib/posts";
import { format } from "date-fns";
import { ja } from "date-fns/locale";

interface BlogCardProps {
  post: PostMeta;
}

export default function BlogCard({ post }: BlogCardProps) {
  return (
    <article className="bg-white border border-slate-200 rounded-xl p-6 hover:border-blue-300 hover:shadow-md transition-all group">
      <Link href={`/blog/${post.slug}`} className="block">
        <div className="flex flex-wrap gap-2 mb-3">
          {post.tags.map((tag) => (
            <span
              key={tag}
              className="px-2 py-0.5 bg-blue-50 text-blue-700 text-xs rounded font-medium"
            >
              {tag}
            </span>
          ))}
        </div>
        <h2 className="text-xl font-bold text-slate-900 mb-2 group-hover:text-blue-600 transition-colors leading-tight">
          {post.title}
        </h2>
        {post.description && (
          <p className="text-slate-600 text-sm leading-relaxed mb-4 line-clamp-2">
            {post.description}
          </p>
        )}
        <div className="flex items-center gap-3 text-slate-400 text-xs">
          <time dateTime={post.date}>
            {format(new Date(post.date), "yyyy年M月d日", { locale: ja })}
          </time>
          {post.readingTime && <span>{post.readingTime} 分</span>}
        </div>
      </Link>
    </article>
  );
}
