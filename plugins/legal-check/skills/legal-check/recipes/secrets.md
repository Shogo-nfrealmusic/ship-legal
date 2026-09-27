# Recipe: exposed secrets (API keys in client code or in the repo)

Goal: no secret key ships to browsers/apps or sits in git. Public-by-design keys are fine:
Supabase anon key, Firebase web config apiKey, Stripe publishable `pk_`, PostHog project
key, Mapbox `pk.` token.

## Done when
- Secret values are out of source: read from server-side env (`process.env.X` in server
  code, `os.environ["X"]`, `ENV["X"]`, `Deno.env.get("X")`), with names added to
  `.env.example` (no values).
- Client code never needs the secret: calls that used it (OpenAI, Stripe secret, Airtable,
  SendGrid, Twilio...) move behind a server endpoint (API route, server action, Edge
  Function, Cloud Function, backend route), which checks the user is signed in and limits
  input size. The client calls that endpoint instead.
- Public env prefixes (`VITE_`, `NEXT_PUBLIC_`, `EXPO_PUBLIC_`, `PUBLIC_`, `REACT_APP_`,
  `NUXT_PUBLIC_`) are never used for secrets; the variable is renamed without the prefix.
- `.env` files with real values are in `.gitignore`; if one is committed, say so. Removing
  it from the working tree isn't enough (git history keeps it).
- Report every key that was exposed as "rotate this key" in Human TODO (the old value is
  compromised the moment it shipped or was pushed). Never print key values.

## Stack notes
- Vite/React (Lovable, Bolt) + Supabase: Edge Function `supabase/functions/<name>/index.ts`
  with `Deno.env.get("OPENAI_API_KEY")`, invoked via `supabase.functions.invoke`.
  Human TODO: `supabase secrets set OPENAI_API_KEY=...` and deploy the function.
- Next.js: route handler `app/api/<name>/route.ts` or a server action.
- Expo: never bundle secrets (anything in the app binary is extractable); use a Firebase
  Cloud Function / Supabase Edge Function / your API.
- Plain HTML: no server → use a serverless function of the host (Netlify/Vercel
  functions) or the vendor's public form endpoint; if you can't, remove the call and
  add a Human TODO.
- Python/Rails: move constants to env (`os.environ.get`, `ENV.fetch`) and fail fast when
  missing in production.
