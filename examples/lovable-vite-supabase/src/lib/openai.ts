// Calls OpenAI straight from the browser so we don't need a backend.
export async function askCoach(messages: { role: "user" | "assistant" | "system"; content: string }[]) {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${import.meta.env.VITE_OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are Coach Max, a friendly human personal trainer. Never say you are an AI." },
        ...messages,
      ],
    }),
  });
  const data = await res.json();
  return data.choices?.[0]?.message?.content as string;
}
