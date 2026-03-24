import fs from "fs";
import path from "path";
import matter from "gray-matter";
import { remark } from "remark";
import remarkGfm from "remark-gfm";
import remarkRehype from "remark-rehype";
import rehypeHighlight from "rehype-highlight";
import rehypeSlug from "rehype-slug";
import rehypeStringify from "rehype-stringify";

const postsDirectory = path.join(process.cwd(), "src/posts");

export interface PostMeta {
  slug: string;
  title: string;
  date: string;
  draft: string;
  description: string;
  tags: string[];
  readingTime?: number;
}

export interface Post extends PostMeta {
  contentHtml: string;
}

function calculateReadingTime(content: string): number {
  const wordsPerMinute = 400;
  const charCount = content.replace(/\s/g, "").length;
  return Math.ceil(charCount / wordsPerMinute);
}

export function getSortedPostsData(): PostMeta[] {
  if (!fs.existsSync(postsDirectory)) return [];

  const fileNames = fs.readdirSync(postsDirectory);
  const allPostsData = fileNames
    .filter((fileName) => fileName.endsWith(".mdx") || fileName.endsWith(".md"))
    .filter((post) => !post.draft) 
    .map((fileName) => {
      const slug = fileName.replace(/\.(mdx|md)$/, "");
      const fullPath = fs.existsSync(path.join(postsDirectory, `${slug}.mdx`))
        ? path.join(postsDirectory, `${slug}.mdx`)
        : path.join(postsDirectory, `${slug}.md`);
      const fileContents = fs.readFileSync(fullPath, "utf8");
      const { data, content } = matter(fileContents);

      return {
        slug,
        title: data.title ?? slug,
        date: data.date ?? "2024-01-01",
        description: data.description ?? "",
        tags: data.tags ?? [],
        readingTime: calculateReadingTime(content),
      } as PostMeta;
    });

  return allPostsData.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getPostData(slug: string): Promise<Post | null> {
  const mdxPath = path.join(postsDirectory, `${slug}.mdx`);
  const mdPath = path.join(postsDirectory, `${slug}.md`);
  const fullPath = fs.existsSync(mdxPath) ? mdxPath : mdPath;

  if (!fs.existsSync(fullPath)) return null;

  const fileContents = fs.readFileSync(fullPath, "utf8");
  const { data, content } = matter(fileContents);

  // remark/rehype で Markdown → HTML に変換（React インスタンス競合を回避）
  const processedContent = await remark()
    .use(remarkGfm)
    .use(remarkRehype, { allowDangerousHtml: true })
    .use(rehypeSlug)
    .use(rehypeHighlight)
    .use(rehypeStringify, { allowDangerousHtml: true })
    .process(content);

  return {
    slug,
    title: data.title ?? slug,
    date: data.date ?? "2024-01-01",
    description: data.description ?? "",
    tags: data.tags ?? [],
    readingTime: calculateReadingTime(content),
    contentHtml: processedContent.toString(),
  };
}
