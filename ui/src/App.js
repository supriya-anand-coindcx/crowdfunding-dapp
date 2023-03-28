import ReactDOM from "react-dom/client";
import * as Constants from "./constants/index";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import React from "react";
import { Home } from "./components/Home";
import { Contribute } from "./components/Contribute";
import { NotFoundPage } from "./components/NotFoundPage";
import { Layout } from "./components/Layout";
import './App.css';

function App() {
  console.log(Constants.ABI_SMART_CONTRACT);
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="blogs" element={<Contribute />} />
          <Route path="contact" element={<Contribute />} />
        </Route>
        <Route path="/projects" element={<Contribute />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);

export default App;