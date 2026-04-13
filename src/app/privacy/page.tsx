import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "プライバシーポリシー",
  description: "tarimasa.dev のプライバシーポリシーです。",
};

export default function PrivacyPage() {
  return (
    <div className="max-w-3xl mx-auto px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-900 mb-2">プライバシーポリシー</h1>
      <p className="text-sm text-slate-500 mb-10">最終更新日：2026年3月25日</p>

      <section className="mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-3">広告の配信について</h2>
        <p className="text-slate-700 leading-relaxed">
          当サイトは Google AdSense を利用して広告を掲載しています。
          Google などの第三者配信事業者は Cookie を使用して、ユーザーが当サイトや他のサイトに過去にアクセスした際の情報に基づいて広告を配信します。
          Google による Cookie の使用を無効にするには、
          <a
            href="https://www.google.com/settings/ads"
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-600 underline mx-1"
          >
            Google 広告設定ページ
          </a>
          をご覧ください。
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-3">アクセス解析について</h2>
        <p className="text-slate-700 leading-relaxed">
          当サイトはアクセス解析のため Google Analytics を使用しています。
          Google Analytics は Cookie を使用してデータを収集しますが、個人を特定する情報は含まれません。
          収集されるデータはGoogle のプライバシーポリシーに基づいて管理されます。
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-3">免責事項</h2>
        <p className="text-slate-700 leading-relaxed">
          当サイトに掲載する情報は正確性を期していますが、内容の完全性・正確性を保証するものではありません。
          当サイトの利用により生じたいかなる損害についても責任を負いかねます。
          また、当サイトのリンク先の内容については一切の責任を負いません。
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-3">著作権</h2>
        <p className="text-slate-700 leading-relaxed">
          当サイトに掲載されているコンテンツ（文章・画像・コード等）の著作権は tarimasa に帰属します。
          無断転載・複製はご遠慮ください。
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-3">お問い合わせ</h2>
        <p className="text-slate-700 leading-relaxed">
          プライバシーポリシーに関するご質問は
          <a
            href="mailto:tarimasa.blog@gmail.com"
            className="text-blue-600 underline mx-1"
          >
            tarimasa.blog@gmail.com
          </a>
          までメールにてお問い合わせください。
        </p>
      </section>
    </div>
  );
}
