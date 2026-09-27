import { createClient } from "npm:@supabase/supabase-js@2";

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

Deno.serve(async (req) => {
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";
  const { data } = await admin.auth.getUser(jwt);
  if (!data.user) return new Response("Unauthorized", { status: 401 });
  await admin.auth.admin.deleteUser(data.user.id); // posts, profile, blocks cascade
  return Response.json({ ok: true });
});
