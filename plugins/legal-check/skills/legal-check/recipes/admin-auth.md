# Recipe: protect admin routes and pages

Goal: admin pages and APIs require a signed-in admin, checked on the server.

## Done when
- Every admin API route checks the session AND an admin flag/role server-side before
  doing anything, returning 401/403 otherwise.
- Admin pages don't fetch privileged data with public keys; they call the protected API
  (a page guard alone is not security — anyone can call the API directly).
- The admin list comes from config/env or a role column (`ADMIN_EMAILS`, `role =
  'admin'`), not a hard-coded check in client code.

## Stack notes
- FastAPI: a dependency `def require_admin(request) -> User` that raises
  `HTTPException(401/403)`; add `dependencies=[Depends(require_admin)]` to admin routes. If
  the app has no sessions yet, use HTTP Basic with credentials from env
  (`fastapi.security.HTTPBasic`, `secrets.compare_digest`) as a stopgap and say so.
- Flask: a `@admin_required` decorator; Django: `@staff_member_required` /
  `user_passes_test`; Rails: `before_action :require_admin`.
- Next.js: check in the route handler / server component (`getServerSession`, Clerk
  `auth()`, Supabase `getUser()`), plus `middleware.ts` for `/admin` pages.
- Express/Hono: middleware on the `/admin` router.
- Vite/React SPA + Supabase: move the admin query into an Edge Function that verifies the
  caller's JWT and an admin claim, then uses the service role; the page shows "Not
  authorized" for others.
