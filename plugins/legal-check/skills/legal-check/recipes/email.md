# Recipe: commercial email (CAN-SPAM) — unsubscribe + postal address

First classify each email. Commercial = promotes a product or service (launch, newsletter,
promo code, re-engagement): needs this fix. Transactional = completes something the user
started (password reset, receipt, login code, security notice): leave it.

## Done when
- Every commercial email has a footer with a working unsubscribe link and a postal
  address placeholder `TODO(legal-check): postal address` read from config/env
  (`COMPANY_POSTAL_ADDRESS`); never invent an address.
- The unsubscribe link carries a signed token (HMAC of the email with a secret from env;
  constant-time compare), so nobody can unsubscribe someone else.
- GET on the link only shows a confirm button (mail scanners open links); POST does the
  unsubscribe and also serves one-click unsubscribe (`List-Unsubscribe-Post`, RFC 8058).
- Sending skips unsubscribed addresses and adds headers `List-Unsubscribe: <url>` and
  `List-Unsubscribe-Post: List-Unsubscribe=One-Click`; the URL is built per recipient
  from the app's public base URL (throw in production if it's missing — a dead link
  breaks the opt-out).
- Unsubscribed addresses are stored where the list lives (table/column/collection); if a
  migration is needed, write it but don't run it.

## Stack notes
- Node (Next API routes, Express, Remix actions, SvelteKit endpoints, Nuxt server
  routes): `crypto.createHmac("sha256", secret)`, `timingSafeEqual`.
- Python (Flask/FastAPI/Django): `hmac.new(secret, email.lower().encode(), hashlib.sha256).hexdigest()`,
  `hmac.compare_digest`; routes `GET/POST /unsubscribe`.
- Rails: `ActiveSupport::MessageVerifier` or `Rails.application.message_verifier(:unsubscribe)`.
- Supabase: an Edge Function `unsubscribe` + an `unsubscribes` table (RLS on, no public
  policies; the function uses the service role).
- No backend (form posts to Mailchimp/ConvertKit/Airtable): hosted ESPs add their own
  unsubscribe + address footer; make sure the template uses them, and put the address
  into the ESP's account settings (Human TODO).

Say in the report: opt-outs must be honored within 10 business days; the link must work
for at least 30 days after sending.
