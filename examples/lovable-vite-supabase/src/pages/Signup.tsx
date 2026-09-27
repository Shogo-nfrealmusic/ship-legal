import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/lib/supabase";

export default function Signup() {
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const [error, setError] = useState("");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) return setError(error.message);
    await supabase.from("profiles").insert({ id: data.user?.id, username, email });
    nav("/coach");
  }

  return (
    <main>
      <h1>Create your account</h1>
      <form onSubmit={submit}>
        <input placeholder="Username" value={username} onChange={(e) => setUsername(e.target.value)} />
        <input placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input placeholder="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        {error && <p>{error}</p>}
        <button type="submit">Sign up</button>
      </form>
    </main>
  );
}
