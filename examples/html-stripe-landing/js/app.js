// Newsletter + SMS tips signup. Sends straight to our Airtable base.
const AIRTABLE_TOKEN = "patFAKEdemo00000000.0000000000000000000000000000000000000000000000000000000000000000";

async function subscribe() {
  const form = document.getElementById("newsletter");
  const data = Object.fromEntries(new FormData(form));
  await fetch("https://api.airtable.com/v0/appFAKE123/Subscribers", {
    method: "POST",
    headers: { Authorization: `Bearer ${AIRTABLE_TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify({ fields: { Email: data.email, Phone: data.phone, Source: "landing" } }),
  });
  form.innerHTML = "<p>You're in! Watch your inbox (and your texts).</p>";
}
