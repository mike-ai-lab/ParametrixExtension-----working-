const https = require('https');

const data = JSON.stringify({
  license_key: "PRM-8393-A23C",
  device_id: "test-device-123"
});

const options = {
  hostname: 'hbslewdkkgwsaohjyzak.supabase.co',
  port: 443,
  path: '/functions/v1/validate-license',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length,
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhic2xld2Rra2d3c2FvaGp5emFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzOTQxNjEsImV4cCI6MjA1ODk3MDE2MX0.63tB5XS7b3SECOqX9BwBJCugAItQUkYmHZutsC7iOgc'
  }
};

const req = https.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);
  
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', body);
  });
});

req.on('error', (e) => {
  console.error(`Error: ${e.message}`);
});

req.write(data);
req.end();