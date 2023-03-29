import { Outlet } from 'react-router-dom';
import Container from 'react-bootstrap/Container';
import Navbar from 'react-bootstrap/Navbar';
import { Welcome } from './welcome';
import '../style/styles.css';

export const Layout = () => {
  return (
    <>
      <Welcome />
      <Navbar bg='dark' expand='lg'>
        <Container className='MyContainer'>
          <div className='MyChild'>
            <button className='ExpandableButton ExpandableButton--blue .ExpandableButton--blue:hover'>
              <Navbar.Brand
                style={{
                  alignItems: 'center',
                  color: 'rgb(80, 80, 82)',
                  fontWeight: 'bold',
                }}
                href='/admin'
              >
                Admin
              </Navbar.Brand>
            </button>
          </div>
          <div className='MyChild'>
            <button className='ExpandableButton ExpandableButton--blue .ExpandableButton--blue:hover'>
              <Navbar.Brand
                style={{
                  alignItems: 'center',
                  color: 'rgb(80, 80, 82)',
                  fontWeight: 'bold',
                }}
                href='/user'
              >
                User
              </Navbar.Brand>
            </button>
          </div>
        </Container>
      </Navbar>
      <Outlet />
    </>
  );
};
