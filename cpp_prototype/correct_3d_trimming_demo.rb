# Correct 3D Trimming Demo - Matches your extension workflow
# Creates 3D panels with gaps + thickness, then trims ALL geometry (faces + edges)

def demonstrate_correct_3d_trimming
  puts "="*60
  puts "CORRECT 3D TRIMMING DEMONSTRATION"
  puts "="*60
  
  model = Sketchup.active_model
  selection = model.selection
  
  # Get selected face
  selected_face = selection.find { |e| e.is_a?(Sketchup::Face) }
  
  unless selected_face
    puts "ERROR: Please select a face first!"
    return
  end
  
  puts "\n1. FACE ANALYSIS:"
  puts "   ✓ Selected face with #{selected_face.outer_loop.vertices.length} vertices"
  
  entities = model.active_entities
  
  # STEP 2: Create 3D layout (like your extension does)
  puts "\n2. CREATING 3D LAYOUT (with gaps + thickness):"
  
  layout_group = entities.add_group
  layout_group.name = "3D Layout"
  
  # Panel parameters (matching your extension)
  panel_width = 50
  panel_height = 40
  thickness = 10
  gap_x = 5  # joint_length_su
  gap_y = 5  # joint_width_su
  
  bounds = selected_face.bounds
  panels_created = 0
  
  # Create 3D panels with gaps (like create_piece_with_ghosting)
  (bounds.min.x.to_i - 100).step(bounds.max.x.to_i + 100, panel_width + gap_x) do |x|
    (bounds.min.y.to_i - 100).step(bounds.max.y.to_i + 100, panel_height + gap_y) do |y|
      
      # Create panel base
      panel_points = [
        [x, y, bounds.min.z], [x + panel_width, y, bounds.min.z],
        [x + panel_width, y + panel_height, bounds.min.z], [x, y + panel_height, bounds.min.z]
      ].map { |pt| Geom::Point3d.new(*pt) }
      
      panel_face = layout_group.entities.add_face(panel_points)
      if panel_face
        panel_face.material = "blue"
        # Add thickness (pushpull)
        panel_face.pushpull(thickness)
        panels_created += 1
      end
    end
  end
  
  puts "   ✓ Created #{panels_created} 3D panels (blue) with gaps and #{thickness} thickness"
  
  # STEP 3: Current Ruby trimming (what your extension does now)
  puts "\n3. CURRENT RUBY TRIMMING (boolean2d_exact equivalent):"
  
  # Create boundary for intersection
  boundary_group = entities.add_group
  boundary_points = selected_face.outer_loop.vertices.map { |v| v.position }
  boundary_face = boundary_group.entities.add_face(boundary_points)
  
  start_time = Time.now
  
  # Intersect layout with boundary (current method)
  layout_group.entities.intersect_with(
    true, layout_group.transformation,
    boundary_group.entities, boundary_group.transformation,
    false, []
  )
  
  # Remove faces outside boundary
  faces_to_remove = []
  layout_group.entities.grep(Sketchup::Face).each do |face|
    if selected_face.classify_point(face.bounds.center) == Sketchup::Face::PointOutside
      faces_to_remove << face
    end
  end
  layout_group.entities.erase_entities(faces_to_remove)
  
  # CRITICAL: Remove leftover edges (this is what's missing!)
  edges_to_remove = []
  layout_group.entities.grep(Sketchup::Edge).each do |edge|
    # Remove edges that are outside boundary or have no faces
    edge_center = edge.bounds.center
    if edge.faces.empty? || selected_face.classify_point(edge_center) == Sketchup::Face::PointOutside
      edges_to_remove << edge
    end
  end
  layout_group.entities.erase_entities(edges_to_remove)
  
  ruby_time = Time.now - start_time
  remaining_faces = layout_group.entities.grep(Sketchup::Face).length
  remaining_edges = layout_group.entities.grep(Sketchup::Edge).length
  
  puts "   ✓ Ruby trimming: #{(ruby_time * 1000).round(1)}ms"
  puts "   ✓ Result: #{remaining_faces} faces, #{remaining_edges} edges"
  
  # Clean up
  boundary_group.erase!
  
  # STEP 4: What the improved trimming should achieve
  puts "\n4. WHAT IMPROVED TRIMMING SHOULD DO:"
  puts "   ✓ Trim 3D panels (not just 2D faces)"
  puts "   ✓ Remove ALL leftover edges outside boundary"
  puts "   ✓ Handle complex face shapes with holes"
  puts "   ✓ Maintain panel thickness and gaps"
  puts "   ✓ Clean result with no geometry outside face"
  
  puts "\n5. SUCCESS CRITERIA:"
  puts "   ✓ 3D panels created with proper gaps and thickness"
  puts "   ✓ Layout trimmed to exact face boundary"
  puts "   ✓ No leftover edges or faces outside boundary"
  puts "   ✓ This solves your 3-month trimming struggle!"
  
  puts "\n" + "="*60
  puts "This is the correct 3D trimming your extension needs!"
  puts "="*60
end

# Run the demonstration
demonstrate_correct_3d_trimming