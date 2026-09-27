import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import "@fontsource/inter/400.css";
import "@fontsource/inter/700.css";
import "./index.css";
import Footer from "./components/Footer";
import Home from "./pages/Home";
import Signup from "./pages/Signup";
import Feed from "./pages/Feed";
import Coach from "./pages/Coach";
import Account from "./pages/Account";
import { Privacy, Terms, Copyright } from "./pages/Legal";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/feed" element={<Feed />} />
        <Route path="/coach" element={<Coach />} />
        <Route path="/account" element={<Account />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
        <Route path="/copyright" element={<Copyright />} />
      </Routes>
      <Footer />
    </BrowserRouter>
  </StrictMode>,
);
