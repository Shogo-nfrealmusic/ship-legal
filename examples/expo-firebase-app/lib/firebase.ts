import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const app = initializeApp({
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: "instavibe-demo.firebaseapp.com",
  projectId: "instavibe-demo",
  storageBucket: "instavibe-demo.appspot.com",
});

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
