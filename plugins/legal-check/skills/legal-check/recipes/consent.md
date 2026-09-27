# Recipe: consent for analytics, replay and ad pixels (EU consent, CCPA "sharing")

Goal: non-essential trackers (analytics with cookies, session replay, ad pixels such as
Meta, TikTok, Google Ads, LinkedIn, X, Pinterest, Reddit, Snap) load only after an
explicit "Accept"; "Decline" is as easy as "Accept"; Global Privacy Control (GPC) is
honored for ad pixels; if ad pixels remain, there is a "Your Privacy Choices / Do Not
Sell or Share My Personal Information" link.

## Done when
- No tracker script runs, and no tracker cookie is set, before Accept (the vendor snippet
  is moved into a loader function called from Accept, or from startup only when a saved
  "yes" exists).
- Accept and Decline buttons have equal prominence; the choice is saved (localStorage /
  cookie / AsyncStorage) and can be changed later from a footer link ("Cookie settings").
- If `navigator.globalPrivacyControl === true`, ad pixels never load (treat as Decline for
  advertising) — web only.
- If ad pixels stay, the footer has "Your Privacy Choices" (or "Do Not Sell or Share My
  Personal Information") linking to a page/section where the visitor can opt out, which
  sets the same saved "no" for advertising.
- Cookieless analytics (Plausible, Fathom, Umami, Vercel Web Analytics) may stay
  ungated.

## Stack notes
- React (Next, Vite, Remix): a `ConsentBanner` client component + `lib/consent.ts` with
  `loadTrackers()`; read the saved choice in `useEffect` (never during SSR); render
  nothing until read. Keep callbacks stable (module functions) so effects run once.
- Vue/Nuxt: a `ConsentBanner.vue` component in the root layout / `app.vue`, logic in a
  client-only plugin (`plugins/consent.client.ts`).
- SvelteKit / Svelte: `ConsentBanner.svelte` in `+layout.svelte`, guard with `browser`.
- Astro: a small `<script>` island in the base layout.
- Plain HTML: move each inline vendor snippet into `js/consent.js` functions
  (`loadGtag()`, `loadMetaPixel()`, ...); add the banner markup and the footer link to
  every page (or the shared include).
- Flask / FastAPI / Django / Rails templates: same as plain HTML, in the base template.
- Expo / React Native: ad SDKs (react-native-fbsdk-next, etc.) → initialize only after
  consent; on iOS, request App Tracking Transparency (`expo-tracking-transparency`)
  before any tracking — Apple requires ATT permission to track across apps.

## Banner copy (adapt)
"We use cookies for analytics and ads to improve <App> and measure our marketing.
[Accept] [Decline] — Privacy Policy"
