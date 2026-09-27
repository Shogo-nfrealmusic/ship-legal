# Recipe: neutral age screen (COPPA)

Goal: stop collecting data from users you would then know are under 13, without hinting
which answer gets them in. If the app looks directed to children, an age screen is NOT
enough (verifiable parental consent is needed): put that in Human TODO, don't code it.

## Done when
- Sign-up asks birth month + year (or full date) before the account exists; every year
  selectable, no pre-selected adult year, no "you must be 13+" text next to it, no
  "I am over 13" checkbox.
- The age is checked where the user can't bypass it (server, edge function, backend);
  a client-only check is acceptable only for a static site with no backend, and you
  must say so.
- Under 13: no account, nothing stored (not even the email); neutral message
  ("Sorry, we can't create an account for you right now."); a ~24 h marker (cookie /
  AsyncStorage / session) blocks an immediate retry with another year.
- Only `is13Plus: true` (or similar) is stored, not the birth date.

## Stack notes
- Next.js / Remix / SvelteKit / Nuxt / Astro SSR: check in the route handler / action /
  server endpoint before creating the user.
- Vite/React SPA + Supabase: move sign-up into a Supabase Edge Function that checks the
  age and calls `auth.admin.createUser` with the service-role key from `Deno.env`; the
  page calls `supabase.functions.invoke("signup", { body })`. If you can't add a function,
  add a database check instead (e.g. a `profiles.is_13_plus` column with
  `check (is_13_plus)`) and say the client check alone is bypassable.
- Firebase (web or Expo): check in a Cloud Function (callable) that creates the user
  with the Admin SDK, or at least block in the client AND in Firestore rules
  (`request.resource.data.is13Plus == true` on the user doc); say which you did.
- Expo / React Native: use two pickers (or TextInputs with number pads) for month and
  year; store the 24 h block in AsyncStorage/SecureStore if available, else in memory.
- Flask / FastAPI / Django / Rails: validate in the POST handler / form / model before
  saving; set a signed cookie (`set_cookie(..., max_age=86400, httponly=True)`).
- OAuth-only sign-up: show the screen before redirecting to the provider and check the
  marker in the OAuth callback before creating the user.
- Month + year lets someone who turns 13 later this month through; ask the day too if the
  project needs it exact.

## Age helper (any language)
age = currentYear - birthYear; if currentMonth < birthMonth: age -= 1
