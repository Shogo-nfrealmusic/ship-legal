# Recipe: session replay (CIPA) — masking, consent, disclosure

Goal: typed text is masked, nothing is recorded before the visitor agrees, and the
privacy policy says recordings happen.

1. Masking (per tool)
   - PostHog: inputs are masked by default. Remove any `maskAllInputs: false`
     (or set it to `true`). Do not add `maskInputOptions` that unmask fields.
   - Microsoft Clarity: inputs are masked by default. Do not switch masking to "Relaxed"
     in the Clarity dashboard (that setting lives outside the code: Human TODO to check).
   - LogRocket: records every input except `type="password"` by default. Add
     `LogRocket.init(APP_ID, { dom: { inputSanitizer: true } })`
     (`textSanitizer: true` also masks page text).
   - Sentry Replay, Hotjar, FullStory, Mouseflow, others: do not claim their defaults.
     Remove any option in the code that turns masking off, and add a Human TODO to
     confirm the tool's masking settings in its dashboard.
2. Consent gate: load the tool only after an explicit "Accept". Do not call its init
   on page load with an "opted out" flag: PostHog's `opt_out_capturing_by_default` stops
   capture but still sets its cookie before consent.
   - PostHog:
     ```ts
     // lib/analytics.ts
     let started = false;
     export function acceptTracking() {          // call on Accept, and on load if consent was saved
       if (started) return; started = true;
       posthog.init(KEY, { api_host: HOST, person_profiles: "identified_only" }); // default input masking
     }
     export function declineTracking() { if (started) posthog.opt_out_capturing(); }
     ```
     Keep `<PostHogProvider client={posthog}>` if the app uses the React hooks; calls
     made before init are ignored.
   - Script-tag tools (Clarity, Hotjar, LogRocket, FullStory...): do not load or init the
     tool until consent is given.
   - If there is no consent UI yet, add a small banner component (see below).
3. Disclosure: the privacy policy must name the tool and say sessions are recorded,
   what is masked, and how to decline. If there is no privacy policy, the `policies`
   recipe creates one.

Minimal consent banner (React, client component). "Decline" must be as easy as "Accept".
```tsx
"use client";
import { useEffect, useState } from "react";
export function ConsentBanner({ onAccept, onDecline }: { onAccept: () => void; onDecline: () => void }) {
  const [choice, setChoice] = useState<string | null | undefined>(undefined);
  useEffect(() => {
    let saved: string | null = null;
    try { saved = localStorage.getItem("consent"); } catch {}
    setChoice(saved);
    if (saved === "yes") onAccept();
  }, [onAccept]);
  if (choice !== null) return null; // undefined = not loaded yet; "yes"/"no" = decided
  const decide = (v: "yes" | "no") => {
    try { localStorage.setItem("consent", v); } catch {}
    v === "yes" ? onAccept() : onDecline();
    setChoice(v);
  };
  return (
    <div role="dialog" aria-label="Cookie consent" style={{ position: "fixed", bottom: 16, left: 16, right: 16, padding: 16, background: "#fff", border: "1px solid #ddd", borderRadius: 12 }}>
      We use analytics and session recordings (typed text is masked) to improve this site.
      See our <a href="/privacy">Privacy Policy</a>.
      <button onClick={() => decide("yes")}>Accept</button>{" "}
      <button onClick={() => decide("no")}>Decline</button>
    </div>
  );
}
```
Pass stable callbacks (module-level functions or `useCallback`) so the effect runs once.
