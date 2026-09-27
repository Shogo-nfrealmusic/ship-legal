"use client";

export default function PricingPage() {
  async function subscribe() {
    const res = await fetch("/api/checkout", { method: "POST" });
    const { url } = await res.json();
    window.location.href = url;
  }

  return (
    <main>
      <h1>Vibely Pro</h1>
      <p style={{ fontSize: 32, fontWeight: 800 }}>$12<span style={{ fontSize: 16 }}>/mo</span></p>
      <ul>
        <li>Unlimited vibes</li>
        <li>Custom profile themes</li>
        <li>See who viewed your vibe</li>
      </ul>
      <button onClick={subscribe}>Go Pro</button>
    </main>
  );
}
