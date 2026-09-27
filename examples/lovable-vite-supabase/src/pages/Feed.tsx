import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Post = { id: string; username: string; body: string; photo_url: string | null };

export default function Feed() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [body, setBody] = useState("");

  useEffect(() => {
    supabase.from("posts").select("*").order("created_at", { ascending: false }).then(({ data }) => setPosts(data ?? []));
  }, []);

  async function share(e: React.FormEvent) {
    e.preventDefault();
    const file = (document.getElementById("photo") as HTMLInputElement).files?.[0];
    let photo_url: string | null = null;
    if (file) {
      const { data } = await supabase.storage.from("photos").upload(`${Date.now()}-${file.name}`, file);
      photo_url = data ? supabase.storage.from("photos").getPublicUrl(data.path).data.publicUrl : null;
    }
    await supabase.from("posts").insert({ body, photo_url });
    setBody("");
  }

  return (
    <main>
      <h2>Community</h2>
      <form onSubmit={share}>
        <textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Share your workout" />
        <input id="photo" type="file" accept="image/*" />
        <button type="submit">Post</button>
      </form>
      {posts.map((p) => (
        <article key={p.id}>
          <b>@{p.username}</b>
          <p>{p.body}</p>
          {p.photo_url && <img src={p.photo_url} />}
        </article>
      ))}
    </main>
  );
}
