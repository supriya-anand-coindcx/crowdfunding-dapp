import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import React from "react";
import { Admin } from "./components/Admin";
import { User } from "./components/User";
import { NotFoundPage } from "./components/NotFoundPage";
import { Layout } from "./components/Layout";
import './App.css';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
        </Route>
        <Route path="admin" element={<Admin />} />
        <Route path="user" element={<User />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);

export default App;