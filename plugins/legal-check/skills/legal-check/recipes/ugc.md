# Recipe: user-generated content — report, block, moderate (App Store 1.2, TAKE IT DOWN Act)

Goal: anyone can report a post or user, users can block abusive users, reports reach a
human, and there is a published contact. Platforms that mainly host user content must
remove nonconsensual intimate images within 48 hours of a valid request.

## Done when
- Each post/comment/profile shows a "Report" action that stores a report (item id,
  reporter, reason, time) where only admins can read it, and confirms to the user.
- Users can block another user; blocked users' content is hidden for them.
- A contact for reports is published (terms/footer/settings), with a
  `TODO(legal-check): monitored email` placeholder, and the terms say you review reports
  promptly and remove content that breaks the rules — including intimate images shared
  without consent within 48 hours of a valid request.
- Mobile (App Store/Play): the same actions are reachable in the app, not only on the web.

## Stack notes
- Supabase: tables `reports` (RLS on; insert policy `with check (auth.uid() = reporter_id)`,
  no select policy for normal users) and `blocks` (RLS: owner-only); feed query filters
  blocked ids.
- Firebase: `reports` collection writable by signed-in users, not readable (rules);
  `users/{uid}/blocks/{otherUid}`.
- SQL backends (Flask/FastAPI/Django/Rails/Prisma/Drizzle): `reports` and `blocks` tables
  + POST routes that require login; write the migration, don't run it.
- Plain listing sites without accounts: a "Report" mailto/link per item is acceptable.
Human TODO: decide who reviews reports and how fast; add a keyword filter if the app
has open text posting (App Store asks for "a method for filtering objectionable material").
