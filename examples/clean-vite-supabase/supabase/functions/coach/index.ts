Deno.serve(async (req) => {
  const { question } = await req.json();
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}` },
    body: JSON.stringify({ model: "gpt-4o-mini", messages: [{ role: "user", content: String(question).slice(0, 2000) }] }),
  });
  const data = await res.json();
  return Response.json({ answer: data.choices?.[0]?.message?.content ?? "" });
});
