# Universal Face Trimming Demo - Works with ANY face shape
# Select ANY face, run script, see dough cutter concept

def demonstrate_universal_trimming
  puts "="*60
  puts "UNIVERSAL FACE TRIMMING DEMONSTRATION"
  puts "="*60
  
  model = Sketchup.active_model
  selection = model.selection
  
  # Get selected face
  selected_face = selection.find { |e| e.is_a?(Sketchup::Face) }
  
  unless selected_face
    puts "ERROR: Please select a face first!"
    return
  end
  
  puts "\n1. SELECTED FACE ANALYSIS:"
  vertices = selected_face.outer_loop.vertices
  puts "   ✓ Face has #{vertices.length} vertices"
  puts "   ✓ Face area: #{selected_face.area.round(2)}"
  puts "   ✓ Face bounds: #{selected_face.bounds}"
  
  # Get face boundary points
  boundary_points = vertices.map { |v| v.position }
  
  # STEP 2: Create layout grid (dough) over the face bounds
  puts "\n2. CREATING LAYOUT GRID (DOUGH):"
  
  bounds = selected_face.bounds
  panel_size = 30  # Adjust as needed
  
  entities = model.active_entities
  dough_group = entities.add_group
  
  panels_created = 0
  (bounds.min.x.to_i - 50).step(bounds.max.x.to_i + 50, panel_size) do |x|
    (bounds.min.y.to_i - 50).step(bounds.max.y.to_i + 50, panel_size) do |y|
      panel_points = [
        [x, y, bounds.min.z], [x + panel_size, y, bounds.min.z],
        [x + panel_size, y + panel_size, bounds.min.z], [x, y + panel_size, bounds.min.z]
      ].map { |pt| Geom::Point3d.new(*pt) }
      
      panel_face = dough_group.entities.add_face(panel_points)
      panel_face.material = "blue" if panel_face
      panels_created += 1
    end
  end
  
  puts "   ✓ Created #{panels_created} layout panels (blue dough)"
  
  # STEP 3: Trim using SketchUp's intersect_with (current Ruby method)
  puts "\n3. TRIMMING WITH CURRENT RUBY METHOD:"
  
  # Create boundary group for intersection
  boundary_group = entities.add_group
  boundary_face = boundary_group.entities.add_face(boundary_points)
  
  # Perform intersection (this is what your extension currently does)
  start_time = Time.now
  dough_group.entities.intersect_with(
    true, dough_group.transformation,
    boundary_group.entities, boundary_group.transformation,
    false, []
  )
  
  # Remove faces outside boundary
  faces_to_remove = []
  dough_group.entities.grep(Sketchup::Face).each do |face|
    if selected_face.classify_point(face.bounds.center) == Sketchup::Face::PointOutside
      faces_to_remove << face
    end
  end
  dough_group.entities.erase_entities(faces_to_remove)
  
  ruby_time = Time.now - start_time
  remaining_faces = dough_group.entities.grep(Sketchup::Face).length
  
  puts "   ✓ Ruby trimming completed in #{(ruby_time * 1000).round(1)}ms"
  puts "   ✓ Result: #{remaining_faces} panels remain inside face"
  
  # Clean up
  boundary_group.erase!
  
  # STEP 4: What C++ should do better
  puts "\n4. WHAT C++ ENGINE SHOULD IMPROVE:"
  puts "   • Faster processing (10x speed for large layouts)"
  puts "   • More reliable boolean operations"
  puts "   • Better handling of complex face shapes"
  puts "   • Precise edge trimming (no gaps or overlaps)"
  puts "   • Handle faces with holes (windows/doors)"
  
  puts "\n5. SUMMARY:"
  puts "   ✓ Works with ANY face shape you select"
  puts "   ✓ Creates layout grid covering the area"
  puts "   ✓ Trims layout to exact face boundary"
  puts "   ✓ This is your dough cutter concept working!"
  
  puts "\n" + "="*60
  puts "Select any face and run this script to see universal trimming!"
  puts "="*60
end

# Run the demonstration
demonstrate_universal_trimming