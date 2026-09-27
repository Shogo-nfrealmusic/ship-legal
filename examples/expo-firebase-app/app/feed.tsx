import { useEffect, useState } from "react";
import { FlatList, Image, Text, TouchableOpacity, View } from "react-native";
import * as ImagePicker from "expo-image-picker";
import { addDoc, collection, onSnapshot, orderBy, query } from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { auth, db, storage } from "@/lib/firebase";
import { suggestCaption } from "@/lib/caption";

type Post = { id: string; uid: string; imageUrl: string; caption: string };

export default function Feed() {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    const q = query(collection(db, "posts"), orderBy("createdAt", "desc"));
    return onSnapshot(q, (snap) => setPosts(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Post, "id">) }))));
  }, []);

  async function post() {
    const pick = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"] });
    if (pick.canceled) return;
    const blob = await (await fetch(pick.assets[0].uri)).blob();
    const r = ref(storage, `posts/${Date.now()}.jpg`);
    await uploadBytes(r, blob);
    const caption = await suggestCaption("a photo from my day");
    await addDoc(collection(db, "posts"), { uid: auth.currentUser?.uid, imageUrl: await getDownloadURL(r), caption, createdAt: Date.now() });
  }

  return (
    <View style={{ flex: 1, paddingTop: 60 }}>
      <FlatList
        data={posts}
        keyExtractor={(p) => p.id}
        renderItem={({ item }) => (
          <View>
            <Image source={{ uri: item.imageUrl }} style={{ width: "100%", aspectRatio: 1 }} />
            <Text>{item.caption}</Text>
          </View>
        )}
      />
      <TouchableOpacity onPress={post} style={{ position: "absolute", bottom: 40, right: 24 }}>
        <Text style={{ fontSize: 40 }}>＋</Text>
      </TouchableOpacity>
    </View>
  );
}
