# Recipe: subscriptions (California Automatic Renewal Law)

Goal: before paying, people see the renewal terms right next to the subscribe button,
actively agree, and can cancel online by themselves.

## Done when
- In visual proximity to every subscribe/upgrade button (same card, directly above or
  below, readable size and contrast): price and frequency ("$12 charged every month"),
  that it continues until cancelled, how to cancel (when a cancellation takes effect is a
  billing setting you can't see: `TODO(legal-check)`); trial: when it ends and what is
  charged. Use the real price from the code; never guess (TODO if unknown).
- An unchecked consent checkbox ("I agree to the automatic renewal terms above") must be
  ticked before the button works; if a server creates the checkout, it rejects requests
  without consent.
- The hosted checkout repeats the terms where possible (Stripe Checkout
  `custom_text.submit.message`).
- A self-serve cancel path exists: e.g. Stripe Customer Portal
  (`stripe.billingPortal.sessions.create({ customer, return_url })`) behind a visible
  "Manage or cancel subscription" link in account settings. If the customer id isn't
  stored, say so and add Human TODO (webhook `checkout.session.completed`).

## Stack notes
- Stripe Payment Link / pricing table on a static page (no backend): put the disclosure +
  checkbox next to the link (disable the link until checked with a few lines of JS);
  enable "customer portal" and share its login link (Stripe's no-code customer portal
  link) in the footer/account area — Human TODO to turn it on and paste the URL.
- Server frameworks (Next, Remix, Express, Flask, FastAPI, Django, Rails): portal route
  that looks up the signed-in user's customer id and redirects (303).
- Expo / React Native with in-app purchases (RevenueCat, StoreKit): Apple/Google handle
  renewal terms and cancellation in the store; add the disclosure text near the paywall
  button and a "Manage subscription" button that opens the store's subscription page
  (`Linking.openURL("https://apps.apple.com/account/subscriptions")` on iOS,
  `https://play.google.com/store/account/subscriptions` on Android).

Do not claim every renewal must be refunded, or cite the FTC click-to-cancel rule (the
8th Circuit vacated it on 2025-07-08).
