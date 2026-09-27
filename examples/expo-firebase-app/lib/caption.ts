// Writes a caption for the photo with GPT, straight from the app.
export async function suggestCaption(description: string): Promise<string> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${process.env.EXPO_PUBLIC_OPENAI_API_KEY}` },
    body: JSON.stringify({ model: "gpt-4o-mini", messages: [{ role: "user", content: `Write a fun caption for: ${description}` }] }),
  });
  const data = await res.json();
  return data.choices?.[0]?.message?.content ?? "";
}
