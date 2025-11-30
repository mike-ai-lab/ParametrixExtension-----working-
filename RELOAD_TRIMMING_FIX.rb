# EXACT RELOAD SEQUENCE TO FIX TRIMMING
# Run this in SketchUp Ruby Console

# 1. Remove conflicting modules
Object.send(:remove_const, :PARAMETRIX_TRIMMING) rescue nil
Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) rescue nil

# 2. Load ONLY the correct trimming module
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/trimming_v4_enhanced.rb'

# 3. Verify it loaded correctly
if defined?(PARAMETRIX_TRIMMING_V4)
  puts "✓ CORRECT TRIMMING MODULE LOADED: #{PARAMETRIX_TRIMMING_V4::VERSION}"
else
  puts "✗ TRIMMING MODULE FAILED TO LOAD"
end

puts "TRIMMING FIX COMPLETE - Test the extension now"