# Load Updated PARAMETRIX with Enhanced Trimming V4
# Copy/paste this entire block into SketchUp Ruby Console

# Force reload all modules
if defined?(PARAMETRIX)
  Object.send(:remove_const, :PARAMETRIX) rescue nil
end
if defined?(PARAMETRIX_TRIMMING_V4)
  Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) rescue nil
end

# Load PARAMETRIX
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/PARAMETRIX.rb'

# Verify version
puts "\n" + "="*60
puts "[VERIFICATION] Checking PARAMETRIX Trimming Version..."
puts "="*60
if defined?(PARAMETRIX_TRIMMING_V4)
  version = PARAMETRIX_TRIMMING_V4.version
  if version == "V4_ENHANCED_MULTIPOINT_2024"
    puts "✓ SUCCESS: Enhanced Trimming V4 loaded correctly!"
    puts "✓ Version: #{version}"
    puts "\nYou are using the UPDATED version with multi-point trimming."
  else
    puts "✗ WARNING: Unexpected version: #{version}"
  end
else
  puts "✗ ERROR: PARAMETRIX_TRIMMING_V4 not loaded!"
  puts "Check that trimming_v4_enhanced.rb exists in lib/PARAMETRIX/"
end
puts "="*60 + "\n"
