import { useState } from "react";
import { supabase } from "@/lib/supabase";

const THIS_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 101 }, (_, i) => THIS_YEAR - i);

export default function Signup() {
  const [message, setMessage] = useState("");

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const body = Object.fromEntries(new FormData(e.currentTarget));
    // Age check and account creation happen in the `signup` Edge Function (server side).
    const { data, error } = await supabase.functions.invoke("signup", { body });
    setMessage(error ? "Sorry, we can't create an account for you right now." : data.message);
  }

  return (
    <main>
      <h1>Create your account</h1>
      <form onSubmit={submit}>
        <label>Email <input name="email" type="email" required /></label>
        <label>Password <input name="password" type="password" minLength={8} required /></label>
        <label>Birth month
          <select name="birthMonth" required defaultValue="">
            <option value="" disabled>Month</option>
            {Array.from({ length: 12 }, (_, i) => <option key={i} value={i + 1}>{i + 1}</option>)}
          </select>
        </label>
        <label>Birth year
          <select name="birthYear" required defaultValue="">
            <option value="" disabled>Year</option>
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </label>
        <button type="submit">Sign up</button>
      </form>
      <p role="status">{message}</p>
    </main>
  );
}
