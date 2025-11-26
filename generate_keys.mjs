// generate_keys.mjs
import { writeFile } from 'fs/promises';
import crypto from 'crypto';

async function generateKeys() {
  // Generate 2048-bit RSA key pair
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

  // Save private key
  await writeFile('private_key.pem', privateKey);
  console.log('✅ private_key.pem created');

  // Save public key
  await writeFile('public_key.pem', publicKey);
  console.log('✅ public_key.pem created');
}

generateKeys().catch(err => console.error(err));
