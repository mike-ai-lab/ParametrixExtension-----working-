const crypto = require('crypto');
const fs = require('fs');

// Generate RSA key pair
const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: {
    type: 'spki',
    format: 'pem'
  },
  privateKeyEncoding: {
    type: 'pkcs8',
    format: 'pem'
  }
});

// Save keys to files
fs.writeFileSync('private_key.pem', privateKey);
fs.writeFileSync('public_key.pem', publicKey);

console.log('RSA keys generated successfully!');
console.log('\nPrivate Key (for Supabase environment variable):');
console.log(privateKey);
console.log('\nPublic Key (for Ruby license manager):');
console.log(publicKey);