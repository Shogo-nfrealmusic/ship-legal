type NewUser = { email: string; password: string; ageVerified13Plus: boolean };
const users: NewUser[] = [];
export async function createUser(u: NewUser) { users.push(u); }
export async function findUserByEmail(email: string) { return users.find((u) => u.email === email); }
