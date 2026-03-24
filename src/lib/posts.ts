import fs from "fs";
import path from "path";
import matter from "gray-matter";

const postsDirectory = path.join(process.cwd(), "src/posts");

export interface PostMeta {
  slug: string;
  title: string;
  date: string;
  description: string;
  tags: string[];
  readingTime?: number;
}

export interface Post extends PostMeta {
  content: string;
}

function calculateReadingTime(content: string): number {
  const wordsPerMinute = 400; // 日本語は1分400字程度
  const charCount = content.replace(/\s/g, "").length;
  return Math.ceil(charCount / wordsPerMinute);
}

export function getSortedPostsData(): PostMeta[] {
  if (!fs.existsSync(postsDirectory)) return [];

  const fileNames = fs.readdirSync(postsDirectory);
  const allPostsData = fileNames
    .filter((fileName) => fileName.endsWith(".mdx"))
    .map((fileName) => {
      const slug = fileName.replace(/\.mdx$/, "");
      const fullPath = path.join(postsDirectory, fileName);
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
  const fullPath = path.join(postsDirectory, `${slug}.mdx`);

  if (!fs.existsSync(fullPath)) return null;

  const fileContents = fs.readFileSync(fullPath, "utf8");
  const { data, content } = matter(fileContents);

  return {
    slug,
    title: data.title ?? slug,
    date: data.date ?? "2024-01-01",
    description: data.description ?? "",
    tags: data.tags ?? [],
    readingTime: calculateReadingTime(content),
    content,
  };
}
