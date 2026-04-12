import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#eff6ff",
          500: "#3b82f6",
          600: "#2563eb",
          700: "#1d4ed8",
          900: "#1e3a5f",
        },
        microsoft: {
          blue: "#0078d4",
          darkBlue: "#003f6b",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "monospace"],
      },
      typography: {
        DEFAULT: {
          css: {
            maxWidth: "none",
            code: {
              backgroundColor: "#f1f5f9",
              borderRadius: "0.25rem",
              padding: "0.125rem 0.375rem",
            },
          },
        },
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};

export default config;
