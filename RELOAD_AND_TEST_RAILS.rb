# Quick Reload and Test Rails Generation
# Copy/paste this into the SketchUp Ruby Console

puts "\n" + "="*60
puts "[TEST] Reloading PARAMETRIX with Fixed Rail Generation"
puts "="*60

# Force reload
Object.send(:remove_const, :PARAMETRIX) if defined?(PARAMETRIX)
Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) if defined?(PARAMETRIX_TRIMMING_V4)
Object.send(:remove_const, :CladzPARAMETRIXMultiFacePosition) if defined?(CladzPARAMETRIXMultiFacePosition)

# Load updated PARAMETRIX
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/PARAMETRIX.rb'

puts "[TEST] PARAMETRIX reloaded successfully!"
puts "[TEST] Rails detection now uses actual trimmed face bounds"
puts "[TEST] Tolerance increased from 0.1 to 0.5 units for more reliable edge detection"
puts "[TEST] Rails enabled: top=#{PARAMETRIX.class_variable_get(:@@enable_top_rail)}, bottom=#{PARAMETRIX.class_variable_get(:@@enable_bottom_rail)}"
puts "\n" + "="*60
puts "[TEST] Steps to test:"
puts "1. Select a rectangular face on your layout"
puts "2. Use PARAMETRIX > Generate Layout"
puts "3. Make sure 'Enable Top Rail' and 'Enable Bottom Rail' are checked"
puts "4. Click Generate to create the layout"
puts "5. Check the console output - it should show rail edges found!"
puts "="*60 + "\n"

