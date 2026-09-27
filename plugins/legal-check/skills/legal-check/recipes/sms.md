# Recipe: text messages (TCPA) — written consent + STOP

Goal: marketing texts go only to people who explicitly agreed in writing to receive
marketing texts, and STOP works.

## Done when
- Phone collection for marketing texts has a separate, unchecked checkbox (never required
  to sign up or buy) with clear text: "I agree to receive recurring marketing text
  messages from <App> at this number. Consent is not a condition of purchase. Msg & data
  rates may apply. Reply STOP to cancel, HELP for help." plus links to Terms and Privacy.
- The consent is stored with a timestamp and the exact wording/version
  (`smsConsentAt`, `smsConsentText`); sending code sends marketing texts only to numbers
  with stored consent (not a default `true`).
- Incoming STOP / UNSUBSCRIBE / CANCEL / END / QUIT marks the number opted out, and
  sending skips opted-out numbers. With Twilio Messaging Services, STOP is handled by
  Twilio Advanced Opt-Out, but your app must still record it (webhook) and stop sending.
- Transactional/OTP texts (login codes) don't need the marketing checkbox; keep them
  separate from promos.

## Stack notes
- Web forms (any framework / plain HTML): add the checkbox under the phone field; send
  `smsConsent: true` only when checked; backend stores timestamp + wording.
- Expo / React Native: a `Switch` or checkbox component with the same text; default off.
- Firebase Cloud Functions / Supabase Edge Functions / Python / Rails: filter the send
  query on consent (`where("smsConsent", "==", true)`), add an inbound webhook for STOP.
Human TODO: register your number for A2P 10DLC with your SMS provider (US carriers
require it for application-to-person texting).
