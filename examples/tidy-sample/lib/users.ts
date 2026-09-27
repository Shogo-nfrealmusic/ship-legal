import { randomBytes, scryptSync, timingSafeEqual } from "node:crypto";

type User = { email: string; passwordHash: string; ageVerified13Plus: boolean };
const users: User[] = [];

// Passwords are stored as salted scrypt hashes, never as typed.
function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  return `${salt}:${scryptSync(password, salt, 64).toString("hex")}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  const a = Buffer.from(hash, "hex");
  const b = scryptSync(password, salt, 64);
  return a.length === b.length && timingSafeEqual(a, b);
}

export async function createUser(u: { email: string; password: string; ageVerified13Plus: boolean }) {
  users.push({ email: u.email, passwordHash: hashPassword(u.password), ageVerified13Plus: u.ageVerified13Plus });
}
export async function findUserByEmail(email: string) { return users.find((u) => u.email === email); }
export async function deleteUserByEmail(email: string) {
  const i = users.findIndex((u) => u.email === email);
  if (i >= 0) users.splice(i, 1);
}
export async function exportUserData(email: string) {
  const u = users.find((x) => x.email === email);
  return u ? { email: u.email, ageVerified13Plus: u.ageVerified13Plus } : null;
}
