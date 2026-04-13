import Link from "next/link";
import { getSortedPostsData } from "@/lib/posts";

export default function Sidebar() {
  const posts = getSortedPostsData();

  const tagCounts = posts.reduce(
    (acc, post) => {
      post.tags.forEach((tag) => {
        acc[tag] = (acc[tag] || 0) + 1;
      });
      return acc;
    },
    {} as Record<string, number>
  );

  return (
    <aside className="space-y-6">
      {/* プロフィール */}
      <div className="bg-white border border-slate-200 rounded-xl p-6">
        <h2 className="text-base font-bold text-slate-900 mb-4 pb-2 border-b border-slate-200">
          プロフィール
        </h2>
        <div className="text-center mb-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/icon.jpg"
            alt="tarimasa"
            className="w-20 h-20 rounded-full mx-auto mb-3 object-cover"
          />
          <h3 className="font-bold text-slate-900">tarimasa</h3>
          <p className="text-sm text-slate-600 mt-1">大手SIer セールスSE</p>
        </div>
        <p className="text-sm text-slate-700 leading-relaxed">
          教育委員会・医療機関向けにゼロトラスト提案を担当。SC-100保有。
        </p>
        <p className="text-sm text-slate-500 leading-relaxed mt-2">
          Sales Engineer at a major SIer. Specializing in Zero Trust and cloud security. Microsoft Certified: Cybersecurity Architect Expert (SC-100).
        </p>
      </div>

      {/* カテゴリー */}
      <div className="bg-white border border-slate-200 rounded-xl p-6">
        <h2 className="text-base font-bold text-slate-900 mb-4 pb-2 border-b border-slate-200">
          カテゴリー
        </h2>
        {Object.keys(tagCounts).length > 0 ? (
          <ul className="space-y-2">
            {Object.entries(tagCounts).map(([tag, count]) => (
              <li key={tag}>
                <Link
                  href={`/tags/${tag}`}
                  className="flex items-center justify-between text-sm text-slate-700 hover:text-blue-600 transition-colors py-1"
                >
                  <span>{tag}</span>
                  <span className="bg-slate-100 text-slate-500 text-xs px-2 py-0.5 rounded-full">
                    {count}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-sm text-slate-500">カテゴリーなし</p>
        )}
      </div>
    </aside>
  );
}
