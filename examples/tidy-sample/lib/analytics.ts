import posthog from "posthog-js";

// PostHog is not loaded at all until the visitor clicks Accept, so no cookie is set and
// no request is sent before consent. Session recording keeps PostHog's default input
// masking (inputs are masked unless maskAllInputs is set to false).
let started = false;

export function grantConsent() {
  if (started) return;
  started = true;
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY ?? "", {
    api_host: "https://us.i.posthog.com",
    person_profiles: "identified_only",
  });
}

export function denyConsent() {
  if (started) posthog.opt_out_capturing();
}
