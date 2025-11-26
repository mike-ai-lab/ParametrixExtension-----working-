# PARAMETRIX License System Setup

## 1. Database Setup

1. Open your Supabase dashboard
2. Go to SQL Editor
3. Run the contents of `database_schema.sql`

## 2. Generate RSA Key Pair

Run these commands in PowerShell:

```powershell
# Generate private key
openssl genpkey -algorithm RSA -out private_key.pem -pkcs8 -pass pass:your_password

# Generate public key
openssl rsa -pubout -in private_key.pem -out public_key.pem -passin pass:your_password

# Display keys for copying
Get-Content private_key.pem
Get-Content public_key.pem
```

## 3. Configure Edge Function

1. Install Supabase CLI: `npm install -g supabase`
2. Login: `supabase login`
3. Create edge function: `supabase functions new validate-license`
4. Copy contents of `edge_function.js` to the created function
5. Set environment variables in Supabase dashboard:
   - `RSA_PRIVATE_KEY`: Your private key (full PEM format)
6. Deploy: `supabase functions deploy validate-license --project-ref YOUR_PROJECT_REF`

## 4. Configure Ruby Extension

1. Replace `<RSA_PUBLIC_KEY>` in `license_manager.rb` with your public key
2. Replace `<SUPABASE_URL>` with your actual Supabase URL

## 5. Setup Admin Tools

```bash
cd node_scripts
npm install
```

Replace placeholders in `admin.js`:
- `<SUPABASE_URL>`: Your Supabase project URL
- `<SUPABASE_SERVICE_KEY>`: Your service role key

## 6. Usage Examples

### Generate Trial License
```bash
node admin.js generate "John Doe" --trial
```

### Generate Full License
```bash
node admin.js generate "Jane Smith" --full
```

### Revoke License
```bash
node admin.js revoke PRM-1234-5678
```

### List All Licenses
```bash
node admin.js list
```

## 7. Security Notes

- Keep your RSA private key secure
- Use environment variables for sensitive data
- The service role key should only be used server-side
- JWT tokens expire after 7 days and require re-validation
- Device binding prevents license sharing

## 8. File Structure

```
PARAMETRIX_EXTENSION/
├── database_schema.sql          # Database setup
├── lib/PARAMETRIX/
│   └── license_manager.rb       # Ruby license validation
├── node_scripts/
│   ├── admin.js                 # License admin tool
│   ├── edge_function.js         # Supabase edge function
│   └── package.json             # Node dependencies
└── PARAMETRIX.rb                # Main extension (with license check)
```

## 9. Troubleshooting

- **"Invalid license key format"**: Ensure format is PRM-XXXX-XXXX
- **"License is bound to a different device"**: License can only be used on one machine
- **"Unable to contact license server"**: Check internet connection and Supabase URL
- **"JWT validation failed"**: Check RSA public key configuration