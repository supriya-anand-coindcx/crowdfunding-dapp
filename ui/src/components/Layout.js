import { Outlet } from "react-router-dom";
import Container from 'react-bootstrap/Container';
import Navbar from 'react-bootstrap/Navbar';
import { Welcome } from "./welcome";

export const Layout = () => {
  return (
    <>
    <Welcome />
    <Navbar bg="dark" expand="lg">
      <Container>
        <Navbar.Brand href="/admin">Admin</Navbar.Brand>
        <Navbar.Brand href="/user">User</Navbar.Brand>
      </Container>
    </Navbar>
    <Outlet />
    </>
  );
}