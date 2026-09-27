import { useState } from "react";
import { supabase } from "@/lib/supabase";

export default function Account() {
  const [done, setDone] = useState(false);

  async function exportData() {
    const { data } = await supabase.from("posts").select("*");
    const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = "my-stride-data.json";
    a.click();
  }

  async function deleteAccount() {
    if (!confirm("Delete your account and all your posts? This can't be undone.")) return;
    await supabase.functions.invoke("delete-account");
    await supabase.auth.signOut();
    setDone(true);
  }

  return (
    <main>
      <h1>Your account</h1>
      <button onClick={exportData}>Download my data</button>{" "}
      <button onClick={deleteAccount}>Delete my account</button>
      {done && <p role="status">Your account was deleted.</p>}
    </main>
  );
}
