import posthog from "posthog-js";

// PostHog starts opted out. Nothing is captured or recorded until the visitor accepts.
// Session recording keeps PostHog's default input masking (maskAllInputs: true).
export function initAnalytics() {
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY ?? "", {
    api_host: "https://us.i.posthog.com",
    opt_out_capturing_by_default: true,
    disable_session_recording: true,
  });
}

export function grantConsent() {
  posthog.opt_in_capturing();
  posthog.startSessionRecording();
}

export function denyConsent() {
  posthog.opt_out_capturing();
}
