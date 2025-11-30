# PARAMETRIX OOB V7 Reload Script
# Clear cache and reload with version verification

puts "\n" + "="*60
puts "RELOADING PARAMETRIX - OOB TRIM V7"
puts "="*60

# Force unload all PARAMETRIX modules
if defined?(PARAMETRIX)
  Object.send(:remove_const, :PARAMETRIX)
  puts "[RELOAD] Removed PARAMETRIX module"
end

if defined?(PARAMETRIX_TRIMMING)
  Object.send(:remove_const, :PARAMETRIX_TRIMMING)
  puts "[RELOAD] Removed PARAMETRIX_TRIMMING module"
end

if defined?(PARAMETRIX_TRIMMING_V4)
  Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4)
  puts "[RELOAD] Removed PARAMETRIX_TRIMMING_V4 module"
end

# Clear loaded files
$LOADED_FEATURES.delete_if { |f| f.include?('PARAMETRIX') }
puts "[RELOAD] Cleared loaded features cache"

# Reload extension
load File.join(__dir__, 'PARAMETRIX.rb')

puts "\n" + "="*60
puts "RELOAD COMPLETE - CHECK VERSION ABOVE"
puts "="*60 + "\n"
