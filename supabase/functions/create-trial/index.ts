import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create } from 'https://deno.land/x/djwt@v2.8/mod.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SENDER_EMAIL = 'support@mimevents.com';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function sendTrialEmail(userName, userEmail) {
  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: `PARAMETRIX <${SENDER_EMAIL}>`,
        to: [userEmail],
        subject: 'Welcome to your PARAMETRIX 7-Day Trial!',
        html: `
          <h1>Welcome, ${userName}!</h1>
          <p>Your 7-day trial for the PARAMETRIX SketchUp extension has been successfully activated.</p>
          <p>Your trial is associated with this email address and is locked to the device you activated it on.</p>
          <p>Enjoy using the extension!</p>
          <p>The PARAMETRIX Team</p>
        `,
      }),
    });
    if (!response.ok) {
      console.error('Resend API Error:', await response.text());
    }
  } catch (error) {
    console.error('Failed to send trial email:', error);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { name, email, device_id } = await req.json();

    if (!name || !email || !device_id) {
      return new Response(JSON.stringify({ error: 'Missing name, email, or device_id' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const privateKey = Deno.env.get('RSA_PRIVATE_KEY')!;

    // Create a new trial license
    const licenseKey = `PRM-TRIAL-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    const { data: newLicense, error: insertError } = await supabase
      .from('licenses')
      .insert({
        license_key: licenseKey,
        user_name: name,
        email: email,
        device_hash: device_id,
        expires_at: expiresAt.toISOString(),
        is_trial: true,
        status: 'active',
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    // Send the welcome email (don't block the response for this)
    sendTrialEmail(name, email);

    // Generate JWT
    const key = await crypto.subtle.importKey(
      'pkcs8',
      new TextEncoder().encode(privateKey),
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const payload = {
      license_key: newLicense.license_key,
      device_id: newLicense.device_hash,
      is_trial: newLicense.is_trial,
      exp: Math.floor(expiresAt.getTime() / 1000),
    };

    const jwt = await create({ alg: 'RS256', typ: 'JWT' }, payload, key);

    return new Response(JSON.stringify({ jwt_token: jwt }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Server error' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
