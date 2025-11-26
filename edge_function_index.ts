import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts";

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SENDER_EMAIL = 'support@mimevents.com';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function sendActivationEmail(userName, userEmail, licenseKey) {
  if (!userEmail) return; // Don't send if no email is associated
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
        subject: 'Your PARAMETRIX License is Activated!',
        html: `
          <h1>Activation Successful, ${userName}!</h1>
          <p>Your PARAMETRIX license key (<strong>${licenseKey}</strong>) has been successfully activated.</p>
          <p>Your license is associated with this email address and is now locked to the device you activated it on.</p>
          <p>Thank you for your purchase!</p>
          <p>The PARAMETRIX Team</p>
        `,
      }),
    });
    if (!response.ok) {
      console.error('Resend API Error:', await response.text());
    }
  } catch (error) {
    console.error('Failed to send activation email:', error);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { license_key, device_id } = await req.json();
    if (!license_key || !device_id) {
      return new Response(JSON.stringify({ valid: false, error: 'Missing license_key or device_id' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const privateKey = Deno.env.get('RSA_PRIVATE_KEY')!;

    const { data: license, error } = await supabase.from('licenses').select('*').eq('license_key', license_key).single();

    if (error || !license) {
      return new Response(JSON.stringify({ valid: false, error: 'License not found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404
      });
    }

    if (license.status === 'revoked') {
      return new Response(JSON.stringify({ valid: false, error: 'License has been revoked' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403
      });
    }

    if (license.expires_at && new Date(license.expires_at) < new Date()) {
      return new Response(JSON.stringify({ valid: false, error: 'License has expired' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403
      });
    }

    if (license.device_hash && license.device_hash !== device_id) {
      return new Response(JSON.stringify({ valid: false, error: 'License is bound to a different device' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403
      });
    }

    // Bind device and send email on first activation
    if (!license.device_hash) {
      await supabase.from('licenses').update({ device_hash: device_id, last_validated: new Date().toISOString() }).eq('license_key', license_key);
      // Send email only for full licenses on first activation
      if (!license.is_trial) {
        sendActivationEmail(license.user_name, license.email, license.license_key);
      }
    } else {
      await supabase.from('licenses').update({ last_validated: new Date().toISOString() }).eq('license_key', license_key);
    }

    // Generate JWT
    const key = await crypto.subtle.importKey('pkcs8', new TextEncoder().encode(privateKey), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
    
    // Set expiration: use license expiration if it exists, otherwise default to 1 year for lifetime licenses
    const expiresAt = license.expires_at ? new Date(license.expires_at) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

    const payload = {
      license_key,
      device_id,
      is_trial: license.is_trial,
      user_name: license.user_name,
      exp: Math.floor(expiresAt.getTime() / 1000),
    };

    const jwt = await create({ alg: 'RS256', typ: 'JWT' }, payload, key);

    return new Response(JSON.stringify({ valid: true, jwt_token: jwt }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ valid: false, error: 'Server error' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});