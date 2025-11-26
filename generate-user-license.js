// Simple license generation for users
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://hbslewdkkgwsaohjyzak.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhic2xld2Rra2d3c2FvaGp5emFrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MzM5NDE2MSwiZXhwIjoyMDU4OTcwMTYxfQ.xbpxYHH5UCdszrAQc39GBgkwBNjzCzOo79M1vonSoyM'
);

async function generateUserLicense(userName, email, licenseType = 'trial') {
  const licenseKey = `PRM-${Math.random().toString(16).substr(2, 4).toUpperCase()}-${Math.random().toString(16).substr(2, 4).toUpperCase()}`;
  
  const expiresAt = licenseType === 'trial' 
    ? new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    : null;

  const { data, error } = await supabase
    .from('licenses')
    .insert([{
      license_key: licenseKey,
      user_name: userName,
      user_email: email,
      license_type: licenseType,
      expires_at: expiresAt,
      issued_at: new Date().toISOString(),
      revoked: false
    }]);

  if (error) {
    console.error('Error:', error);
    return null;
  }

  // Email template
  const emailContent = `
Dear ${userName},

Thank you for choosing PARAMETRIX! Your license key is ready.

LICENSE KEY: ${licenseKey}

INSTALLATION INSTRUCTIONS:
1. Install the PARAMETRIX extension in SketchUp
2. Click the PARAMETRIX toolbar icon
3. Enter your license key when prompted
4. Start creating amazing layouts!

${licenseType === 'trial' ? 'Your trial expires in 7 days.' : 'Your license never expires.'}

Need help? Contact us at support@parametrix.com

Best regards,
PARAMETRIX Team
  `;

  console.log('License generated successfully!');
  console.log('License Key:', licenseKey);
  console.log('Email Content:');
  console.log(emailContent);
  
  return { licenseKey, emailContent };
}

// Usage examples:
if (require.main === module) {
  const args = process.argv.slice(2);
  const userName = args[0] || 'Test User';
  const email = args[1] || 'test@example.com';
  const licenseType = args[2] || 'trial';
  
  generateUserLicense(userName, email, licenseType);
}

module.exports = { generateUserLicense };