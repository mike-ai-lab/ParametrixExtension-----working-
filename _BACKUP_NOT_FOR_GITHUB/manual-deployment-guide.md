# Manual Edge Function Deployment

## Deploy via Supabase Dashboard

1. Go to https://supabase.com/dashboard/project/hbslewdkkgwsaohjyzak/functions
2. Click "Create a new function"
3. Name: `validate-license`
4. Copy the contents of `supabase/functions/validate-license/index.ts` into the editor
5. Click "Deploy function"

## Set Environment Variables

1. Go to Edge Functions > Settings
2. Add environment variable:
   - Key: `RSA_PRIVATE_KEY`
   - Value: Your private key (full PEM format including headers)

## Function URL
Your function will be available at:
`https://hbslewdkkgwsaohjyzak.supabase.co/functions/v1/validate-license`

## Update Ruby License Manager

Replace `<SUPABASE_URL>` in `lib/PARAMETRIX/license_manager.rb` with:
`https://hbslewdkkgwsaohjyzak.supabase.co`