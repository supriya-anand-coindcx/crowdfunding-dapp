import { Outlet, Link } from "react-router-dom";

export const Layout = () => {
  return (
    <>
      <nav>
        <ul>
        <Link to="/">Home</Link>
        <Link to="/blogs">Blogs</Link>
        <Link to="/contact">Contact</Link>
        </ul>
      </nav>

      <Outlet />
    </>
  )
};