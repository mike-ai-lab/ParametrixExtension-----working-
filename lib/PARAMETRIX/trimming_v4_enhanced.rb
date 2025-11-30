# PARAMETRIX Trimming V8 - Cookie Cutter Method

module PARAMETRIX_TRIMMING_V4

  VERSION = "V8.2_TRANSFORM_FIX"

  def self.version
    puts "[PARAMETRIX] Trimming Version: #{VERSION}"
    VERSION
  end

  def self.boolean2d_exact(layout_group, original_face, face_matrix = nil)
    begin
      puts "[V8.2] Starting cookie-cutter trim..."
      model = Sketchup.active_model
      return layout_group unless model && layout_group && original_face

      if layout_group.is_a?(Sketchup::Group)
        layout_ents = layout_group.entities
        layout_transform = layout_group.transformation
      elsif layout_group.is_a?(Sketchup::ComponentInstance)
        layout_ents = layout_group.definition.entities
        layout_transform = layout_group.transformation
      else
        return layout_group
      end

      # Store original faces BEFORE adding boundary
      original_faces = layout_ents.grep(Sketchup::Face)
      face_count = original_faces.length
      puts "[V8.2] Layout has #{face_count} faces before trimming"
      
      # Get layout Z level
      sample_face = original_faces.first
      layout_z = sample_face ? sample_face.vertices.first.position.z : 0.0
      puts "[V8.2] Layout local Z: #{layout_z.round(4)}"

      # Create boundary INSIDE the layout group
      world_to_local = layout_transform.inverse
      outer_points = original_face.outer_loop.vertices.map do |v|
        p = v.position
        p = p.transform(face_matrix) if face_matrix && face_matrix != Geom::Transformation.new
        p_local = p.transform(world_to_local)
        Geom::Point3d.new(p_local.x, p_local.y, layout_z)
      end

      # Create temp boundary group inside layout
      boundary_group = layout_ents.add_group
      boundary_ents = boundary_group.entities
      
      # Add outer loop
      boundary_face = boundary_ents.add_face(outer_points)
      
      unless boundary_face && boundary_face.valid?
        puts "[V8.2] Failed to create boundary face"
        boundary_group.erase!
        return layout_group
      end
      
      # Add inner loops (holes) - OOB method
      if original_face.loops.length > 1
        original_face.loops[1..-1].each do |loop|
          hole_points = loop.vertices.map do |v|
            p = v.position
            p = p.transform(face_matrix) if face_matrix && face_matrix != Geom::Transformation.new
            p_local = p.transform(world_to_local)
            Geom::Point3d.new(p_local.x, p_local.y, layout_z)
          end
          hole_face = boundary_ents.add_face(hole_points)
          hole_face.erase! if hole_face && hole_face.valid?
        end
        puts "[V8.2] Added #{original_face.loops.length - 1} inner loops (holes)"
      end

      puts "[V8.2] Running intersect_with (OOB method)..."
      tr = Geom::Transformation.new
      gptr = boundary_group.transformation
      
      # OOB: Intersect TWICE for better results
      layout_ents.intersect_with(false, gptr, layout_ents, tr, false, [boundary_group])
      layout_ents.intersect_with(false, gptr, layout_ents, tr, false, [boundary_group])
      
      faces_after_cut = layout_ents.grep(Sketchup::Face).length
      new_faces = faces_after_cut - face_count
      puts "[V8.2] After intersection: #{faces_after_cut} faces (#{new_faces} new from cuts)"

      # OOB: Remove edges outside boundary (test edge start, end, and midpoint)
      edges_to_remove = []
      layout_ents.grep(Sketchup::Edge).each do |edge|
        if boundary_face.classify_point(edge.start.position) == Sketchup::Face::PointOutside &&
           boundary_face.classify_point(edge.end.position) == Sketchup::Face::PointOutside
          edges_to_remove << edge
        end
        
        # Test edge midpoint
        midpoint = edge.start.position.offset(edge.line[1], edge.length/2)
        if boundary_face.classify_point(midpoint) == Sketchup::Face::PointOutside
          edges_to_remove << edge
        end
      end
      
      puts "[V8.2] Removing #{edges_to_remove.length} outside edges"
      layout_ents.erase_entities(edges_to_remove) unless edges_to_remove.empty?
      
      # OOB: Remove faces in holes
      faces_to_remove = []
      layout_ents.grep(Sketchup::Face).each do |face|
        # Check if face is in a hole (all edges have 2 faces)
        hole = true
        face.outer_loop.edges.each do |e|
          if e.faces.length == 1
            hole = false
            break
          end
        end
        
        if hole
          pt = face.bounds.center.project_to_plane(boundary_face.plane)
          if boundary_face.classify_point(pt) == Sketchup::Face::PointOutside
            faces_to_remove << face
          end
        end
      end
      
      puts "[V8.2] Removing #{faces_to_remove.length} faces in holes"
      layout_ents.erase_entities(faces_to_remove) unless faces_to_remove.empty?
      
      boundary_group.erase!

      lonely_edges = layout_ents.grep(Sketchup::Edge).select { |e| e.faces.empty? }
      layout_ents.erase_entities(lonely_edges) unless lonely_edges.empty?

      remaining = layout_ents.grep(Sketchup::Face).length
      puts "[V8.2] Complete - #{remaining} faces remain"
      
      return layout_group

    rescue => e
      puts "[V8.2] Error: #{e.message}"
      puts e.backtrace[0..3].join("\n")
      boundary_group.erase! if defined?(boundary_group) && boundary_group && boundary_group.respond_to?(:erase!) && boundary_group.valid?
      return layout_group
    end
  end

end
