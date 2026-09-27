import { useState } from "react";
import { Text, TextInput, TouchableOpacity, View } from "react-native";
import { router } from "expo-router";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

export default function SignUp() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [phone, setPhone] = useState("");

  async function signUp() {
    const cred = await createUserWithEmailAndPassword(auth, email, password);
    await setDoc(doc(db, "users", cred.user.uid), { email, phone, dailyTexts: true });
    router.replace("/feed");
  }

  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24 }}>
      <Text style={{ fontSize: 32, fontWeight: "800" }}>InstaVibe</Text>
      <TextInput placeholder="Email" value={email} onChangeText={setEmail} autoCapitalize="none" />
      <TextInput placeholder="Password" value={password} onChangeText={setPassword} secureTextEntry />
      <TextInput placeholder="Phone number" value={phone} onChangeText={setPhone} keyboardType="phone-pad" />
      <Text style={{ fontSize: 10, color: "#bbb" }}>By signing up you'll get daily vibe texts.</Text>
      <TouchableOpacity onPress={signUp} style={{ backgroundColor: "#ec4899", padding: 14, borderRadius: 12 }}>
        <Text style={{ color: "#fff" }}>Create account</Text>
      </TouchableOpacity>
    </View>
  );
}
