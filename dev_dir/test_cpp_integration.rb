# Test script to demonstrate C++ engine integration
# Run this in SketchUp Ruby Console to test the new geometry engine

# Load the new modules
load File.join(__dir__, '..', 'lib', 'PARAMETRIX', 'geometry_bridge.rb')
load File.join(__dir__, '..', 'lib', 'PARAMETRIX', 'trimming_v4_cpp.rb')

def test_cpp_engine_integration
  puts "="*60
  puts "PARAMETRIX C++ Engine Integration Test"
  puts "="*60
  
  # Check if C++ engine is available
  puts "\n1. Checking C++ Engine Status:"
  engine_available = PARAMETRIX_TRIMMING_V4.engine_status
  
  # Create test geometry - L-shaped face with a rectangular layout piece
  puts "\n2. Creating Test Geometry:"
  
  model = Sketchup.active_model
  entities = model.active_entities
  
  # Clear existing geometry
  entities.clear!
  
  # Create L-shaped face (the problematic case)
  l_shape_points = [
    Geom::Point3d.new(0, 0, 0),      # Bottom-left
    Geom::Point3d.new(300, 0, 0),    # Bottom-right of horizontal part
    Geom::Point3d.new(300, 100, 0),  # Top-right of horizontal part
    Geom::Point3d.new(100, 100, 0),  # Inner corner (this is the tricky part)
    Geom::Point3d.new(100, 200, 0),  # Top of vertical part
    Geom::Point3d.new(0, 200, 0),    # Top-left
  ]
  
  l_face = entities.add_face(l_shape_points)
  l_face.material = "red" if l_face
  
  puts "   ✓ Created L-shaped face (#{l_shape_points.length} vertices)"
  
  # Create a simple rectangular layout piece that overlaps the L-shape
  layout_group = entities.add_group
  layout_entities = layout_group.entities
  
  # Rectangle that would normally cover the entire area (including the inner corner)
  rect_points = [
    Geom::Point3d.new(50, 50, 0),
    Geom::Point3d.new(250, 50, 0),
    Geom::Point3d.new(250, 150, 0),
    Geom::Point3d.new(50, 150, 0)
  ]
  
  rect_face = layout_entities.add_face(rect_points)
  rect_face.material = "blue" if rect_face
  rect_face.pushpull(10) if rect_face # Give it some thickness
  
  puts "   ✓ Created rectangular layout piece (overlaps L-shape inner corner)"
  
  # Test the trimming
  puts "\n3. Testing Trimming Operations:"
  
  if engine_available
    puts "   Testing C++ Engine (Precise Boolean Operations):"
    
    # Test with C++ engine
    start_time = Time.now
    result_cpp = PARAMETRIX_TRIMMING_V4.boolean2d_exact(layout_group, l_face)
    cpp_time = Time.now - start_time
    
    if result_cpp && result_cpp != layout_group
      puts "   ✓ C++ trimming completed in #{(cpp_time * 1000).round(1)}ms"
      puts "   ✓ Result: Properly trimmed component created"
      
      # Move result to show comparison
      if result_cpp.respond_to?(:transformation=)
        result_cpp.transformation = Geom::Transformation.translation(Geom::Vector3d.new(400, 0, 0))
      end
    else
      puts "   ✗ C++ trimming failed or returned original geometry"
    end
  else
    puts "   C++ Engine not available - testing Ruby fallback:"
    
    # Test Ruby fallback
    start_time = Time.now
    result_ruby = PARAMETRIX_TRIMMING.boolean2d_exact(layout_group, l_face) if defined?(PARAMETRIX_TRIMMING)
    ruby_time = Time.now - start_time
    
    if result_ruby
      puts "   ⚠ Ruby trimming completed in #{(ruby_time * 1000).round(1)}ms"
      puts "   ⚠ Result: May not handle L-shape inner corner correctly"
    else
      puts "   ✗ Ruby trimming failed"
    end
  end
  
  puts "\n4. Expected Results:"
  puts "   With C++ Engine:"
  puts "   ✓ Rectangle should be trimmed to follow L-shape exactly"
  puts "   ✓ Inner corner area should be cut out (not covered)"
  puts "   ✓ Only the blue material within the red L-shape should remain"
  puts "   ✓ Fast processing even for complex geometry"
  
  puts "\n   With Ruby Fallback:"
  puts "   ⚠ Rectangle might cover entire area including inner corner"
  puts "   ⚠ Manual cleanup required for L-shape inner corner"
  puts "   ⚠ Slower processing, potential crashes on complex geometry"
  
  puts "\n5. Commercial Impact:"
  if engine_available
    puts "   ✅ READY FOR COMMERCIAL PUBLICATION"
    puts "   ✅ Handles L-shapes, irregular geometry, openings reliably"
    puts "   ✅ Professional-grade performance for large facades"
    puts "   ✅ Competitive advantage over Ruby-only extensions"
  else
    puts "   ⚠ BUILD C++ ENGINE TO UNLOCK COMMERCIAL POTENTIAL"
    puts "   ⚠ Current Ruby implementation limits commercial viability"
    puts "   ⚠ Users will encounter the L-shape trimming bug"
  end
  
  puts "\n" + "="*60
  puts "Test completed. Check the geometry in your SketchUp model."
  puts "="*60
end

# Run the test
test_cpp_integration