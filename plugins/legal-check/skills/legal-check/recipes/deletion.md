# Recipe: delete my account / download my data (GDPR, CCPA, App Store 5.1.1(v))

Goal: signed-in users can delete their account and data themselves, and download a copy
of their data. Apps that allow account creation must let users start account deletion
inside the app (Apple); Google Play also wants a web link for deletion requests.

## Done when
- Account settings has "Delete my account" with a confirm step; it deletes the auth user
  and their rows/files (or queues deletion), then signs out. Data you must keep (e.g.
  invoices for tax) is listed in the privacy policy instead of silently kept.
- "Download my data" returns the user's own data as JSON (or CSV).
- Deletion runs with server privileges, never by exposing an admin key to the client.
- The privacy policy explains both, plus a contact for requests.

## Stack notes
- Supabase: Edge Function `delete-account` that reads the caller's JWT
  (`admin.auth.getUser(jwt)`), then `admin.auth.admin.deleteUser(id)`; make foreign keys
  `on delete cascade` (migration) and delete their Storage files.
- Firebase: callable Cloud Function using Admin SDK `auth().deleteUser(uid)` + delete
  `users/{uid}` and their posts/files; or the client `deleteUser(auth.currentUser)` after
  recent login plus Firestore deletes allowed by rules for the owner.
- Next/Remix/SvelteKit/Nuxt/Express/Flask/FastAPI/Django/Rails: an authenticated
  POST/DELETE route that deletes the user and related records in a transaction.
- Expo / React Native: a "Delete account" button in settings calling the above; this is
  required for App Store review when sign-up exists.
Human TODO (Google Play): add the web deletion-request URL in Play Console.
