import { useState } from "react";
import { supabase } from "@/lib/supabase";

export default function Coach() {
  const [q, setQ] = useState("");
  const [a, setA] = useState("");

  async function ask(e: React.FormEvent) {
    e.preventDefault();
    const { data } = await supabase.functions.invoke("coach", { body: { question: q } });
    setA(data?.answer ?? "");
  }

  return (
    <main>
      <h1>AI coach</h1>
      <p>You're chatting with an AI assistant. It can make mistakes and isn't medical advice.</p>
      <form onSubmit={ask}>
        <label>Your question <input value={q} onChange={(e) => setQ(e.target.value)} /></label>
        <button type="submit">Ask</button>
      </form>
      {a && <p>AI: {a}</p>}
    </main>
  );
}
