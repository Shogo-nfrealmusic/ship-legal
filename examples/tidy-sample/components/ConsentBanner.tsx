"use client";

import { useEffect, useState } from "react";
import { denyConsent, grantConsent, initAnalytics } from "@/lib/analytics";

export function ConsentBanner() {
  const [choice, setChoice] = useState<string | null>("pending");

  useEffect(() => {
    initAnalytics();
    const saved = localStorage.getItem("consent");
    setChoice(saved);
    if (saved === "yes") grantConsent();
  }, []);

  if (choice === "yes" || choice === "no" || choice === "pending") return null;

  return (
    <div role="dialog" aria-label="Cookie consent">
      We use PostHog analytics, including session recordings with typed text masked, to improve Tidy Notes.
      <button onClick={() => { localStorage.setItem("consent", "yes"); grantConsent(); setChoice("yes"); }}>Accept</button>
      <button onClick={() => { localStorage.setItem("consent", "no"); denyConsent(); setChoice("no"); }}>Decline</button>
    </div>
  );
}
