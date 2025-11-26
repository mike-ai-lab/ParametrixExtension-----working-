# Get Supabase API Keys

1. Go to: https://supabase.com/dashboard/project/hbslewdkkgwsaohjyzak/settings/api
2. Copy the "anon public" key
3. Replace the placeholder in `license_manager.rb` line with your actual key:

```ruby
request['Authorization'] = 'Bearer YOUR_ANON_KEY_HERE'
```

Or temporarily bypass server validation by commenting out the server check in `validate_license` method.