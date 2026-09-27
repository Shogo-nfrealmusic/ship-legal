import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Post = { id: string; user_id: string; body: string };

export default function Feed() {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    supabase.from("posts").select("id, user_id, body").then(({ data }) => setPosts(data ?? []));
  }, []);

  async function report(post: Post) {
    await supabase.from("reports").insert({ post_id: post.id, reason: "reported from feed" });
    alert("Thanks. Our team reviews reports within 24 hours.");
  }

  async function block(userId: string) {
    await supabase.from("blocks").insert({ blocked_id: userId });
    setPosts((ps) => ps.filter((p) => p.user_id !== userId));
  }

  return (
    <main>
      <h1>Community runs</h1>
      {posts.map((p) => (
        <article key={p.id}>
          <p>{p.body}</p>
          <button onClick={() => report(p)}>Report post</button>{" "}
          <button onClick={() => block(p.user_id)}>Block user</button>
        </article>
      ))}
    </main>
  );
}
