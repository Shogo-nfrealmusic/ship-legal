import { createClient } from "npm:@supabase/supabase-js@2";

// Server side: service role key comes from the Edge Function environment, never the browser.
const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

function ageFrom(year: number, month: number) {
  const now = new Date();
  let age = now.getFullYear() - year;
  if (now.getMonth() + 1 < month) age -= 1;
  return age;
}

Deno.serve(async (req) => {
  const { email, password, birthYear, birthMonth } = await req.json();
  const age = ageFrom(Number(birthYear), Number(birthMonth));
  if (!Number.isFinite(age) || age < 13) {
    // Nothing is stored for under-13s.
    return Response.json({ message: "Sorry, we can't create an account for you right now." }, { status: 403 });
  }
  const { data, error } = await admin.auth.admin.createUser({ email, password });
  if (error) return Response.json({ message: "Sign-up failed." }, { status: 400 });
  await admin.from("profiles").insert({ id: data.user.id, is_13_plus: true });
  return Response.json({ message: "Check your inbox to confirm your email." });
});
