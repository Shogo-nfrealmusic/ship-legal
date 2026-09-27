// Tiny in-memory store so the sample runs without a database.
export type User = {
  id: string;
  email: string;
  name: string;
  handle: string;
  passwordHash: string;
  avatarUrl?: string;
  plan: "free" | "pro";
  stripeCustomerId?: string;
};

const users = new Map<string, User>();
const waitlist = new Set<string>(["early@example.com", "fan@example.com"]);

export const db = {
  createUser(u: Omit<User, "id" | "plan">): User {
    const user: User = { ...u, id: crypto.randomUUID(), plan: "free" };
    users.set(user.id, user);
    return user;
  },
  findByHandle(handle: string): User | undefined {
    return [...users.values()].find((u) => u.handle === handle);
  },
  findById(id: string): User | undefined {
    return users.get(id);
  },
  update(id: string, patch: Partial<User>) {
    const u = users.get(id);
    if (u) users.set(id, { ...u, ...patch });
  },
  waitlistEmails(): string[] {
    return [...waitlist];
  },
};

export async function hashPassword(pw: string): Promise<string> {
  const data = new TextEncoder().encode(pw);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Buffer.from(digest).toString("hex");
}

// Demo only: a real app would read the session cookie.
export function currentUserId(): string {
  return "demo-user";
}
