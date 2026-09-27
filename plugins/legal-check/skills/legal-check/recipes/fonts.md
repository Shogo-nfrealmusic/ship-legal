# Recipe: stop loading Google Fonts from Google's servers (GDPR)

Goal: visitors' browsers never contact fonts.googleapis.com or fonts.gstatic.com.

## Done when
- No `fonts.googleapis.com` / `fonts.gstatic.com` left in source (links, preconnects,
  CSS `@import`), and the same font family and weights still render.

## Stack notes (pick the first that fits)
- Next.js: `next/font/google` self-hosts at build time (no new dependency):
  `const inter = Inter({ subsets: ["latin"], weight: ["400","700"], variable: "--font-inter" })`,
  put `inter.variable` on `<html>`, use `var(--font-inter)` in CSS. Spaces in names → `_`.
- Vite/React, Vue, Svelte/SvelteKit, Astro, Remix: `@fontsource/<font>` —
  `import "@fontsource/inter/400.css"` in the entry file (main.tsx, main.ts, +layout,
  Layout.astro, root.tsx). New dependency: say it, and run the project's install only if
  the user approved installs; otherwise list the command in Human TODO.
  Nuxt: `@nuxt/fonts` module (self-hosts) or @fontsource.
- Plain HTML / Flask / FastAPI / Django / Rails templates: download the .woff2 files into
  the static folder (`static/fonts/`, `public/fonts/`, `app/assets/fonts/`) and add
  `@font-face { font-family: "Inter"; src: url("/static/fonts/inter-400.woff2") format("woff2"); font-weight: 400; font-display: swap; }`.
  You cannot download files: create the CSS, keep the family name, and add a Human TODO
  "download these woff2 files (e.g. from google-webfonts-helper or the font's GitHub
  release) into <folder>". Until then the browser falls back to system fonts, which is
  safe.
- Expo / React Native: fonts are bundled by `expo-font`; Google CDN use there is rare. If
  a WebView loads Google Fonts, treat it like plain HTML.
