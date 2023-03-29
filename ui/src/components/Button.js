import React from 'react';

function Button({ label, type = 'primary', onClick }) {
  const styles = {
    padding: '12px 20px',
    borderRadius: '4px',
    fontSize: '16px',
    fontWeight: 'bold',
    color: type === 'primary' ? '#ffffff' : '#333333',
    backgroundColor: type === 'primary' ? '#0077ff' : '#dddddd',
    border: 'none',
    cursor: 'pointer',
  };

  return (
    <button style={styles} onClick={onClick}>
      {label}
    </button>
  );
}

export default Button;
