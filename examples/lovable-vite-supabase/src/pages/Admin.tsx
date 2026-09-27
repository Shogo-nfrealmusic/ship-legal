import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

// Admin dashboard: all users and their emails.
export default function Admin() {
  const [users, setUsers] = useState<{ id: string; username: string; email: string }[]>([]);
  useEffect(() => {
    supabase.from("profiles").select("id, username, email").then(({ data }) => setUsers(data ?? []));
  }, []);
  return (
    <main>
      <h2>Admin</h2>
      <table>
        <tbody>
          {users.map((u) => (
            <tr key={u.id}><td>{u.username}</td><td>{u.email}</td></tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
