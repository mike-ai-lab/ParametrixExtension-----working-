# Test script to verify the critical fixes
# Run this in SketchUp Ruby Console to test the fixes

puts "[TEST] Loading PARAMETRIX extension..."

# Test 1: Verify trimming module loads correctly
begin
  if defined?(PARAMETRIX_TRIMMING)
    puts "[TEST] ✓ PARAMETRIX_TRIMMING module loaded"
    if PARAMETRIX_TRIMMING.respond_to?(:clone_face_with_holes)
      puts "[TEST] ✓ clone_face_with_holes method available"
    else
      puts "[TEST] ✗ clone_face_with_holes method missing"
    end
  else
    puts "[TEST] ✗ PARAMETRIX_TRIMMING module not loaded"
  end
rescue => e
  puts "[TEST] ✗ Error testing trimming: #{e.message}"
end

# Test 2: Verify core module tolerance
begin
  if defined?(PARAMETRIX) && PARAMETRIX.class_variable_defined?(:@@tolerance)
    puts "[TEST] ✓ Tolerance constant defined"
  else
    puts "[TEST] ✗ Tolerance constant missing"
  end
rescue => e
  puts "[TEST] ✗ Error testing tolerance: #{e.message}"
end

# Test 3: Verify namespacing fix
begin
  if defined?(PARAMETRIX::MultiFacePosition)
    puts "[TEST] ✓ PARAMETRIX::MultiFacePosition class available"
    if defined?(CladzPARAMETRIXMultiFacePosition)
      puts "[TEST] ✓ Backward compatibility alias available"
    else
      puts "[TEST] ✗ Backward compatibility alias missing"
    end
  else
    puts "[TEST] ✗ PARAMETRIX::MultiFacePosition class missing"
  end
rescue => e
  puts "[TEST] ✗ Error testing namespacing: #{e.message}"
end

# Test 4: Verify dead code removal
begin
  dead_methods = [
    :filter_and_extend_pieces,
    :generate_single_length_row_with_min_piece,
    :generate_multi_length_row_with_min_piece,
    :trim_piece_to_face_boundary,
    :create_cutting_component_from_layout_NEW_METHOD,
    :oob_face_clone
  ]
  
  removed_count = 0
  dead_methods.each do |method|
    if !PARAMETRIX.respond_to?(method)
      removed_count += 1
    else
      puts "[TEST] ✗ Dead code method still exists: #{method}"
    end
  end
  
  if removed_count == dead_methods.length
    puts "[TEST] ✓ All dead code methods removed (#{removed_count}/#{dead_methods.length})"
  else
    puts "[TEST] ⚠ Some dead code methods still exist (#{removed_count}/#{dead_methods.length} removed)"
  end
rescue => e
  puts "[TEST] ✗ Error testing dead code removal: #{e.message}"
end

puts "[TEST] Test completed. Check results above."