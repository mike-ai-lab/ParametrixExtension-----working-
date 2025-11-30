# Test script to verify trimming functionality is working
# Run this after reloading the extension

def test_trimming_functionality
  puts "="*50
  puts "TESTING PARAMETRIX TRIMMING FUNCTIONALITY"
  puts "="*50
  
  # Check if the correct trimming module is loaded
  if defined?(PARAMETRIX_TRIMMING_V4)
    puts "✓ PARAMETRIX_TRIMMING_V4 module loaded"
    puts "  Version: #{PARAMETRIX_TRIMMING_V4::VERSION}"
    
    # Check if the boolean2d_exact method exists
    if PARAMETRIX_TRIMMING_V4.respond_to?(:boolean2d_exact)
      puts "✓ boolean2d_exact method available"
    else
      puts "✗ boolean2d_exact method NOT found"
    end
  else
    puts "✗ PARAMETRIX_TRIMMING_V4 module NOT loaded"
  end
  
  # Check if old trimming module is still loaded (conflict)
  if defined?(PARAMETRIX_TRIMMING)
    puts "⚠ WARNING: Old PARAMETRIX_TRIMMING module still loaded (potential conflict)"
  else
    puts "✓ No conflicting trimming modules"
  end
  
  # Check if main PARAMETRIX module is loaded
  if defined?(PARAMETRIX)
    puts "✓ Main PARAMETRIX module loaded"
    puts "  Version: #{PARAMETRIX::PARAMETRIX_EXTENSION_VERSION}"
  else
    puts "✗ Main PARAMETRIX module NOT loaded"
  end
  
  puts "="*50
  puts "TEST COMPLETE"
  puts "="*50
  
  # Instructions
  puts "\nTo test trimming:"
  puts "1. Select an irregular face"
  puts "2. Run PARAMETRIX layout generation"
  puts "3. Check if elements outside the face boundary are trimmed"
end

# Run the test
test_trimming_functionality