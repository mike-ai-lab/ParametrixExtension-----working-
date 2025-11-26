# PARAMETRIX Trimming V3 - Proper Layout Trimming Implementation

module PARAMETRIX_TRIMMING

  PARAMETRIX_TRIM_VERSION = "PARAMETRIX_TRIM_V3_1.0"

  def self.boolean2d_exact(layout_group, original_face, face_matrix = nil)
    begin
      puts "[TRIM] Starting boolean trimming..."
      model = Sketchup.active_model
      ents  = model.active_entities
      
      unless model && layout_group && original_face
        puts "[TRIM] Missing required parameters"
        return layout_group
      end

      # Use the original_face passed as parameter, not selection
      faces = [original_face]
      puts "[TRIM] Trimming to face with #{original_face.outer_loop.vertices.length} vertices"

      gp = ents.add_group
      gents = gp.entities

      # Clone the face with proper transformation
      if face_matrix && face_matrix != Geom::Transformation.new
        # Transform vertices if face_matrix is provided
        outer_verts = original_face.outer_loop.vertices.map { |v| v.position.transform(face_matrix) }
        gents.add_face(outer_verts)
        
        # Handle holes
        if original_face.loops.length > 1
          original_face.loops[1..-1].each do |loop|
            hole_verts = loop.vertices.map { |v| v.position.transform(face_matrix) }
            hole_face = gents.add_face(hole_verts)
            hole_face.erase! if hole_face
          end
        end
      else
        # Use face_clone method for proper hole handling
        face_clone(gents, faces)
      end

      boundary_face = gents.grep(Sketchup::Face).first
      unless boundary_face && boundary_face.valid?
        gp.erase! rescue nil
        return layout_group
      end

      # Ensure same normal direction
      boundary_face.reverse! if boundary_face.normal.dot(original_face.normal) < 0
      puts "[TRIM] Boundary face created successfully"

      # Add layout entities to intersect (this is where the trimming happens)
      layout_ents = layout_group.entities
      puts "[TRIM] Layout has #{layout_ents.grep(Sketchup::Face).length} faces before trimming"

      # The key: intersect_with creates the proper trimmed geometry
      layout_ents.intersect_with(
        true,                               # self_intersect: true for proper cutting
        layout_group.transformation,        # Transform for layout entities
        gents,                             # Entities to intersect with (boundary)
        gp.transformation,                 # Transform for boundary entities
        false,                             # solids_only: false for 2D trimming
        []                                 # entities_to_exclude
      )

      puts "[TRIM] Intersection complete"
      
      faces_to_remove = []
      layout_ents.grep(Sketchup::Face).each do |f|
        # Classify the center point of each face against the boundary
        # If PointOutside, the face is outside the boundary and should be removed
        if boundary_face.classify_point(f.bounds.center) == Sketchup::Face::PointOutside
          faces_to_remove << f
        end
      end

      puts "[TRIM] Removing #{faces_to_remove.length} faces outside boundary"
      layout_ents.erase_entities(faces_to_remove)

      lonely_edges = []
      layout_ents.grep(Sketchup::Edge).each do |edge|
        lonely_edges << edge if edge.faces.empty?
      end
      puts "[TRIM] Removing #{lonely_edges.length} lonely edges"
      layout_ents.erase_entities(lonely_edges) unless lonely_edges.empty?

      gp.erase! rescue nil
      puts "[TRIM] Final face count: #{layout_ents.grep(Sketchup::Face).length}"

      # Convert to proper 2D cutting component
      inst = layout_group.to_component
      puts "[TRIM] Converted to component successfully"
      defn = inst.definition
      be = defn.behavior
      be.is2d = true
      be.cuts_opening = true
      be.snapto = 0
      defn.invalidate_bounds

      inst.name = "PARAMETRIX Layout"
      defn.name = "PARAMETRIX Layout Def"

      return inst

    rescue => e
      begin; gp.erase! if gp && gp.respond_to?(:erase!); rescue; end
      return layout_group
    end
  end

  # Face cloning method (handles holes properly)
  def self.face_clone(gents, faces)
    faces2go = []

    faces.each do |face|
      # Create faces for all loops (outer + inner holes)
      face.loops.each { |loop| gents.add_face(loop.vertices) }

      # Re-add outer face to ensure proper structure
      oface = gents.add_face(face.outer_loop.vertices)

      # Find and mark internal faces for removal
      gents.each do |f|
        next if f.class != Sketchup::Face
        f.edges.each do |e|
          if e.faces.length > 1
            faces2go << f
            break
          end
        end
      end
    end

    gents.erase_entities(faces2go) # Remove internal faces (holes)
  end

end