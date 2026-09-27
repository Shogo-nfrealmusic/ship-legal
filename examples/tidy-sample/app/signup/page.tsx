"use client";

import { useState } from "react";

const THIS_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 101 }, (_, i) => THIS_YEAR - i);

export default function SignupPage() {
  const [message, setMessage] = useState("");

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const res = await fetch("/api/signup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(Object.fromEntries(new FormData(e.currentTarget))),
    });
    const data = await res.json();
    setMessage(data.message ?? data.error ?? "");
  }

  return (
    <main>
      <h1>Create your account</h1>
      <form onSubmit={onSubmit}>
        <label>Email<input name="email" type="email" required /></label>
        <label>Password<input name="password" type="password" minLength={8} required /></label>
        {/* Neutral age screen: every year is selectable and nothing hints at a minimum age. */}
        <label>
          Birth month
          <select name="birthMonth" required defaultValue="">
            <option value="" disabled>Month</option>
            {Array.from({ length: 12 }, (_, i) => <option key={i} value={i + 1}>{i + 1}</option>)}
          </select>
        </label>
        <label>
          Birth year
          <select name="birthYear" required defaultValue="">
            <option value="" disabled>Year</option>
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </label>
        <p>By signing up you agree to the <a href="/terms">Terms of Service</a> and <a href="/privacy">Privacy Policy</a>.</p>
        <button type="submit">Sign up</button>
      </form>
      {message && <p>{message}</p>}
    </main>
  );
}
