# Quick Manual Test for Enhanced Trimming
# Load this in SketchUp Ruby Console to test the new trimming

# 1. Load the new trimming module
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/trimming_v4_enhanced.rb'

# 2. Test on selected face
def test_trimming_on_selection
  model = Sketchup.active_model
  selection = model.selection
  
  if selection.empty?
    puts "ERROR: Please select a face first"
    return
  end
  
  face = selection.grep(Sketchup::Face).first
  unless face
    puts "ERROR: No face found in selection"
    return
  end
  
  puts "\n" + "="*60
  puts "Testing Enhanced Trimming on Selected Face"
  puts "="*60
  puts "Face vertices: #{face.outer_loop.vertices.length}"
  puts "Face area: #{face.area.round(2)}"
  puts "Face loops: #{face.loops.length} (#{face.loops.length - 1} holes)"
  
  model.start_operation("Test Trimming", true)
  
  # Create test layout (simple grid)
  ents = model.active_entities
  layout_group = ents.add_group
  layout_ents = layout_group.entities
  
  bounds = face.bounds
  width = bounds.width / 4.0
  height = bounds.height / 4.0
  thickness = 50.mm
  
  # Create 5x5 grid (extends beyond face boundaries)
  5.times do |row|
    5.times do |col|
      x = bounds.min.x - width + col * width
      y = bounds.min.y - height + row * height
      
      pts = [
        Geom::Point3d.new(x, y, 0),
        Geom::Point3d.new(x + width, y, 0),
        Geom::Point3d.new(x + width, y + height, 0),
        Geom::Point3d.new(x, y + height, 0)
      ]
      
      f = layout_ents.add_face(pts)
      f.pushpull(-thickness) if f
    end
  end
  
  puts "\nCreated layout with #{layout_ents.grep(Sketchup::Face).length} faces"
  puts "Applying enhanced trimming..."
  
  # Apply enhanced trimming
  trimmed = PARAMETRIX_TRIMMING_V4.boolean2d_exact(layout_group, face, nil)
  
  if trimmed
    final_faces = trimmed.definition.entities.grep(Sketchup::Face).length
    puts "\nTrimming complete!"
    puts "Final face count: #{final_faces}"
    puts "\nCheck the model - there should be ZERO geometry outside the face boundary"
    puts "="*60
  else
    puts "\nERROR: Trimming failed"
  end
  
  model.commit_operation
end

# Run the test
puts "\n\nTO TEST:"
puts "1. Select any face in your model"
puts "2. Run: test_trimming_on_selection"
puts "\nThe script will create a grid layout and trim it to your face boundary."
puts "Verify visually that NO geometry extends outside the face.\n\n"
