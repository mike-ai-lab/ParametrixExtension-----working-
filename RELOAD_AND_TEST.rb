# Quick reload and test

# Force reload
if defined?(PARAMETRIX_TRIMMING_V4)
  Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) rescue nil
end

load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/trimming_v4_enhanced.rb'

puts "\n[RELOAD] V4 reloaded with debug logging"
puts "[RELOAD] Version: #{PARAMETRIX_TRIMMING_V4.version}"
puts "\nNow run PARAMETRIX on a face and watch console for [TRIM_V4] messages\n"
