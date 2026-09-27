# Recipe: session replay (CIPA) — masking, consent, disclosure

Goal: typed text is masked, nothing records before the visitor agrees, and the privacy
policy says recordings happen. Pair with the `consent` recipe for the banner itself.

## Done when
- No option that turns masking off remains; LogRocket has `dom: { inputSanitizer: true }`.
- The replay tool is not loaded / initialized until consent (see `consent` recipe).
- The privacy policy names the tool, says sessions are recorded, what is masked, and how
  to decline.

## Tool notes
- PostHog: inputs masked by default; remove `maskAllInputs: false`. Call `posthog.init`
  only after consent (do not init on load with an opt-out flag: that still sets a cookie).
  Mobile: posthog-react-native session replay has its own mask options — keep
  `maskAllTextInputs: true`.
- Microsoft Clarity: inputs masked by default; load the tag only after consent. Dashboard
  masking mode ("Strict/Balanced/Relaxed") is outside code → Human TODO.
- LogRocket: records all inputs except passwords by default:
  `LogRocket.init(APP_ID, { dom: { inputSanitizer: true } })`.
- Hotjar, FullStory, Mouseflow, Sentry Replay, others: don't claim their defaults; remove
  any code that turns masking off, load after consent, Human TODO to check the dashboard.
- Plain HTML snippets: wrap the vendor snippet in a function `loadHotjar()` and call it
  from the consent "Accept" handler instead of running it inline.
