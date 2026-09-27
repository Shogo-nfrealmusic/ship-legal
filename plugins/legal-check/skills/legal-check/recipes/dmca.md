# Recipe: DMCA page for user uploads (17 U.S.C. §512(c))

Goal: keep the DMCA safe harbor for content users post. That needs a designated agent
registered with the U.S. Copyright Office AND the agent's contact details on the site.
Code can do the second part only.

## Done when
- A `/dmca` (or `/copyright`) page exists with: how to send a notice (identify the work
  and the infringing URL, contact details, a good-faith statement, a statement that the
  notice is accurate and, under penalty of perjury, that the sender is authorized, a
  signature); the designated agent name, postal address, phone, email as
  `TODO(legal-check): must match your Copyright Office registration`; how to send a
  counter-notice; a repeat-infringer policy.
- Terms say users must have rights to what they post and you may remove content; they
  link to /dmca. The footer links to /dmca.
- A top-of-file code comment marks the page as a draft for lawyer review.

## Stack notes
- File-based routers: Next `app/dmca/page.tsx`, Nuxt `pages/dmca.vue`, SvelteKit
  `src/routes/dmca/+page.svelte`, Astro `src/pages/dmca.astro`, Remix
  `app/routes/dmca.tsx`.
- React Router (Vite/Lovable/Bolt): a component + a `<Route path="/dmca" ...>`.
- Plain HTML: `dmca.html` copying the site's header/footer markup.
- Flask/FastAPI/Django/Rails: a template + a GET route/view.
- Expo / React Native: a screen (e.g. `app/dmca.tsx` with expo-router) linked from
  settings; also host the same text on the web (App Store listing needs a URL).

Human TODO (AI cannot do this): register the agent at https://dmca.copyright.gov ($6;
renew every 3 years), then copy the exact details into the page.
