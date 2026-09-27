# Recipe: database access rules (Supabase RLS, Firebase rules, public buckets)

Goal: the public anon key / client SDK can only read and write what each user should.

## Done when
- Supabase: every table in `public` has `alter table ... enable row level security;` in a
  new migration, with policies that match how the app uses it:
  own rows `using (auth.uid() = user_id)`; public read only where the app shows the data
  to everyone (`for select using (true)`) and never for private columns (emails, phone
  numbers → move them to a private table, or expose a view without them); inserts with
  `with check (auth.uid() = user_id)`. Storage buckets holding private files are
  `public = false` with storage policies; public buckets only for truly public media.
- Admin-only data (all users' emails, orders) is read by a server function with the
  service role after checking an admin claim, never by the browser with the anon key.
- Firebase: replace test-mode / `if true` rules with per-user rules, e.g.
  `match /users/{uid} { allow read, write: if request.auth != null && request.auth.uid == uid; }`,
  `match /posts/{id} { allow read: if true; allow create: if request.auth != null && request.resource.data.uid == request.auth.uid; allow update, delete: if request.auth != null && resource.data.uid == request.auth.uid; }`,
  and Storage rules limiting writes to signed-in users, their own path, and image size/type.
- Write the migration/rules files; do not apply them. Human TODO: run `supabase db push` /
  `firebase deploy --only firestore:rules,storage` after review, then check the Supabase
  Security Advisor.
- If tables were created in the dashboard (no SQL in the repo), you can't see RLS: status
  CHECK, Human TODO to open Supabase → Security Advisor.
