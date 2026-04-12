export default function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white mt-auto">
      <div className="max-w-4xl mx-auto px-4 py-8 flex flex-col md:flex-row items-center justify-between gap-4">
        <p className="text-slate-500 text-sm">
          © {new Date().getFullYear()} tarimasa. Built with Next.js + Azure Static Web Apps.
        </p>
        <div className="flex items-center gap-4 text-sm text-slate-500">
          <a
            href="https://github.com/tarimasa"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-slate-900 transition-colors"
          >
            GitHub
          </a>
          <a
            href="https://www.linkedin.com/in/arimasa-tanimoto-039568395"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-slate-900 transition-colors"
          >
            LinkedIn
          </a>
          <a
            href="/privacy"
            className="hover:text-slate-900 transition-colors"
          >
            プライバシーポリシー
          </a>
        </div>
      </div>
    </footer>
  );
}
