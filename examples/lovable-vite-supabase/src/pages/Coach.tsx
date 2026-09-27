import { useState } from "react";
import { askCoach } from "@/lib/openai";

type Msg = { role: "user" | "assistant"; content: string };

export default function Coach() {
  const [msgs, setMsgs] = useState<Msg[]>([{ role: "assistant", content: "Hey! I'm Max, your coach. What's your goal?" }]);
  const [text, setText] = useState("");

  async function send() {
    const next: Msg[] = [...msgs, { role: "user", content: text }];
    setMsgs(next);
    setText("");
    const reply = await askCoach(next);
    setMsgs([...next, { role: "assistant", content: reply }]);
  }

  return (
    <main>
      <h2>Coach Max</h2>
      {msgs.map((m, i) => (
        <p key={i}><b>{m.role === "user" ? "You" : "Max"}:</b> {m.content}</p>
      ))}
      <input value={text} onChange={(e) => setText(e.target.value)} placeholder="Ask Max…" />
      <div onClick={send} className="send-btn">➤</div>
    </main>
  );
}
