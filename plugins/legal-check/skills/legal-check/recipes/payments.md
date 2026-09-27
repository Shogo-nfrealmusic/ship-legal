# Recipe: payments — refund policy, price clarity, card data (PCI)

## Done when
- Refund/cancellation policy: a page (e.g. `/refunds`, or a section in Terms) states
  refund window or "no refunds" rule, how to request one, and cancellation; linked in the
  footer and near checkout. Placeholders `TODO(legal-check)` for anything the code
  doesn't tell you (window, contact).
- Price clarity: the price shown before checkout includes every mandatory fee (service,
  booking, processing fees); either fold the fee into the displayed price or show the
  total including fees wherever the price is advertised. Taxes and shipping may be shown
  separately.
- Card data: raw card number / CVC / expiry never reach your server, database, or logs.
  Replace your own card inputs with a hosted payment page or hosted fields (Stripe
  Checkout, Payment Links, or Stripe Elements / PaymentElement), delete card columns
  from the schema (write the migration, don't run it), stop storing CVC anywhere, and
  flag existing stored card data for deletion (Human TODO — it's production data).

## Stack notes
- Next / Remix / Express / SvelteKit / Nuxt: server route creates a Stripe Checkout
  Session (`mode: "payment"`) and redirects; success page reads the session id.
- Flask / FastAPI / Django / Rails: same with the `stripe` library
  (`stripe.checkout.Session.create(...)` → redirect 303 to `session.url`); read the
  secret key from env, not code. If the `stripe` package isn't installed, add it to
  requirements/Gemfile and say an install is needed.
- Plain HTML: a Stripe Payment Link (`https://buy.stripe.com/...`) — Human TODO to create
  it in the dashboard and paste the URL.
- Expo / React Native: `@stripe/stripe-react-native` PaymentSheet, or open a Checkout URL
  in the browser. (Digital goods used in-app must use Apple/Google in-app purchase — note
  it, don't build it.)
