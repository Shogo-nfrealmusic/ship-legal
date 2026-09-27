# Recipe: stop loading Google Fonts from Google's servers

Goal: the visitor's browser must not contact fonts.googleapis.com or fonts.gstatic.com.

Pick the first option that fits the project:

1. Next.js (13+): use `next/font/google`. Next downloads the font at build time and
   serves it from your own domain, so browsers never contact Google. No new dependency.
   ```tsx
   // app/layout.tsx
   import { Inter } from "next/font/google";
   const inter = Inter({ subsets: ["latin"], weight: ["400", "600", "800"], display: "swap", variable: "--font-inter" });
   <html lang="en" className={inter.variable}>
   ```
   Then in CSS: `font-family: var(--font-inter), system-ui, sans-serif;`
   Keep the weights/styles the old <link> URL asked for (e.g. `wght@400;600;800`).
   Font names with spaces use underscores: `Playfair_Display`.
2. Any other bundler (Vite, Astro, Remix, SvelteKit...): `@fontsource/<font>` packages.
   `npm install @fontsource/inter` then `import "@fontsource/inter/400.css";` in the entry
   file. This adds a dependency: list the install command in the fix plan and say it
   must be run.
3. Plain HTML: download the .woff2 files into the project and use `@font-face` with a
   local `src: url("/fonts/inter-400.woff2")`.

Then remove every trace of the CDN:
- `<link rel="preconnect" href="https://fonts.googleapis.com">` and `...fonts.gstatic.com`
- `<link href="https://fonts.googleapis.com/css2?...">`
- CSS `@import url("https://fonts.googleapis.com/...")`

Check afterwards: search the project for `fonts.googleapis.com` and `fonts.gstatic.com`.
Both must be gone from source (build output folders don't count).
