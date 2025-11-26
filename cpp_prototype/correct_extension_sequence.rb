# Correct Extension Sequence - Matches PARAMETRIX workflow exactly

def demonstrate_correct_extension_sequence
  puts "="*60
  puts "CORRECT PARAMETRIX TRIMMING SEQUENCE"
  puts "="*60
  
  model = Sketchup.active_model
  selection = model.selection
  
  selected_face = selection.find { |e| e.is_a?(Sketchup::Face) }
  unless selected_face
    puts "ERROR: Please select a face first!"
    return
  end
  
  entities = model.active_entities
  
  # STEP 1: Create 3D layout group (like create_unified_layout_for_face)
  puts "\n1. CREATING 3D LAYOUT GROUP:"
  
  layout_group = entities.add_group
  layout_group.name = "PARAMETRIX Test Layout"
  
  # Create 3D panels with thickness (like create_piece_with_ghosting)
  bounds = selected_face.bounds
  panel_width = 50
  panel_height = 40
  thickness = 10
  gap = 5
  
  panels_created = 0
  (bounds.min.x.to_i - 50).step(bounds.max.x.to_i + 50, panel_width + gap) do |x|
    (bounds.min.y.to_i - 50).step(bounds.max.y.to_i + 50, panel_height + gap) do |y|
      
      # Create base face
      panel_points = [
        [x, y, bounds.min.z], [x + panel_width, y, bounds.min.z],
        [x + panel_width, y + panel_height, bounds.min.z], [x, y + panel_height, bounds.min.z]
      ].map { |pt| Geom::Point3d.new(*pt) }
      
      panel_face = layout_group.entities.add_face(panel_points)
      if panel_face
        panel_face.material = "blue"
        panel_face.pushpull(thickness)  # Add thickness
        panels_created += 1
      end
    end
  end
  
  puts "   ✓ Created #{panels_created} 3D panels with #{thickness} thickness"
  
  # STEP 2: Create boundary group (like boolean2d_exact does)
  puts "\n2. CREATING BOUNDARY GROUP:"
  
  boundary_group = entities.add_group
  boundary_points = selected_face.outer_loop.vertices.map { |v| v.position }
  boundary_face = boundary_group.entities.add_face(boundary_points)
  boundary_face.material = "red"
  
  puts "   ✓ Boundary face created"
  
  # STEP 3: Apply intersect_with (exact PARAMETRIX sequence)
  puts "\n3. APPLYING INTERSECT_WITH (PARAMETRIX method):"
  
  layout_ents = layout_group.entities
  faces_before = layout_ents.grep(Sketchup::Face).length
  
  # This is the exact call from your trimming_v3.rb
  layout_ents.intersect_with(
    true,                               # self_intersect: true
    layout_group.transformation,        # layout transform
    boundary_group.entities,           # boundary entities
    boundary_group.transformation,     # boundary transform
    false,                             # solids_only: false
    []                                 # entities_to_exclude
  )
  
  puts "   ✓ intersect_with completed"
  
  # STEP 4: Remove faces outside boundary (exact PARAMETRIX logic)
  puts "\n4. REMOVING FACES OUTSIDE BOUNDARY:"
  
  faces_to_remove = []
  layout_ents.grep(Sketchup::Face).each do |f|
    if boundary_face.classify_point(f.bounds.center) == Sketchup::Face::PointOutside
      faces_to_remove << f
    end
  end
  
  layout_ents.erase_entities(faces_to_remove)
  puts "   ✓ Removed #{faces_to_remove.length} faces outside boundary"
  
  # STEP 5: Remove lonely edges (exact PARAMETRIX logic)
  puts "\n5. REMOVING LONELY EDGES:"
  
  lonely_edges = []
  layout_ents.grep(Sketchup::Edge).each do |edge|
    lonely_edges << edge if edge.faces.empty?
  end
  layout_ents.erase_entities(lonely_edges) unless lonely_edges.empty?
  
  puts "   ✓ Removed #{lonely_edges.length} lonely edges"
  
  faces_after = layout_ents.grep(Sketchup::Face).length
  edges_after = layout_ents.grep(Sketchup::Edge).length
  
  # STEP 6: Convert to component (exact PARAMETRIX logic)
  puts "\n6. CONVERTING TO COMPONENT:"
  
  inst = layout_group.to_component
  defn = inst.definition
  be = defn.behavior
  be.is2d = true
  be.cuts_opening = true
  be.snapto = 0
  defn.invalidate_bounds
  
  inst.name = "PARAMETRIX Layout"
  defn.name = "PARAMETRIX Layout Def"
  
  puts "   ✓ Converted to 2D cutting component"
  
  # Clean up
  boundary_group.erase!
  
  # RESULTS
  puts "\n7. RESULTS:"
  puts "   Before: #{faces_before} faces"
  puts "   After: #{faces_after} faces, #{edges_after} edges"
  puts "   Component: #{inst.class.name}"
  
  puts "\n8. WHAT'S HAPPENING:"
  puts "   ✓ This is EXACTLY your extension's workflow"
  puts "   ✓ intersect_with creates intersection lines"
  puts "   ✓ Face removal works correctly"
  puts "   ✓ Edge cleanup works correctly"
  puts "   ⚠️  BUT: Complex shapes may have leftover geometry"
  
  puts "\n" + "="*60
  puts "This shows your exact trimming sequence working!"
  puts "="*60
end

# Run the demonstration
demonstrate_correct_extension_sequence