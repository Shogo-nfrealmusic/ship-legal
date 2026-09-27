"use client";

import { useEffect, useState } from "react";
import { denyConsent, grantConsent } from "@/lib/analytics";

export function ConsentBanner() {
  // undefined = not read yet, null = no choice yet, "yes" / "no" = decided
  const [choice, setChoice] = useState<string | null | undefined>(undefined);

  useEffect(() => {
    let saved: string | null = null;
    try { saved = localStorage.getItem("consent"); } catch {}
    setChoice(saved);
    if (saved === "yes") grantConsent();
  }, []);

  if (choice !== null) return null;

  function decide(value: "yes" | "no") {
    try { localStorage.setItem("consent", value); } catch {}
    if (value === "yes") grantConsent(); else denyConsent();
    setChoice(value);
  }

  return (
    <div role="dialog" aria-label="Cookie consent">
      We use PostHog analytics, including session recordings with typed text masked, to improve Tidy Notes.
      <button onClick={() => decide("yes")}>Accept</button>
      <button onClick={() => decide("no")}>Decline</button>
    </div>
  );
}
