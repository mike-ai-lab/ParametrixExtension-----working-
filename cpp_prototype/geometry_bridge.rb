# PARAMETRIX Geometry Bridge
# Interfaces between Ruby extension and C++ geometry engine

module PARAMETRIX_GEOMETRY_BRIDGE

  # Path to the engine (use .bat for development, .exe for production)
  remove_const(:ENGINE_PATH) if defined?(ENGINE_PATH)
  ENGINE_PATH = File.join(__dir__, '..', '..', 'parametrix_engine.exe')
  
  def self.process_layout_with_cpp_engine(face_data, layout_pieces)
    begin
      # Create temporary files for input/output
      input_file = File.join(ENV['TEMP'] || '/tmp', "parametrix_input_#{Time.now.to_i}.json")
      output_file = File.join(ENV['TEMP'] || '/tmp', "parametrix_output_#{Time.now.to_i}.json")
      
      # Convert Ruby data to JSON format for C++ engine
      input_json = create_input_json(face_data, layout_pieces)
      
      # Write input JSON
      File.write(input_file, input_json)
      
      # Execute C++ engine
      command = "\"#{ENGINE_PATH}\" \"#{input_file}\" \"#{output_file}\""
      puts "[PARAMETRIX] Executing C++ engine: #{command}"
      
      result = system(command)
      
      unless result
        puts "[PARAMETRIX] C++ engine execution failed"
        return nil
      end
      
      # Read output JSON
      unless File.exist?(output_file)
        puts "[PARAMETRIX] C++ engine did not produce output file"
        return nil
      end
      
      output_json = File.read(output_file)
      trimmed_pieces = parse_output_json(output_json)
      
      # Cleanup temporary files
      File.delete(input_file) if File.exist?(input_file)
      File.delete(output_file) if File.exist?(output_file)
      
      return trimmed_pieces
      
    rescue => e
      puts "[PARAMETRIX] Error in C++ bridge: #{e.message}"
      return nil
    end
  end
  
  private
  
  def self.create_input_json(face_data, layout_pieces)
    face = face_data[:face]
    matrix = face_data[:matrix] || Geom::Transformation.new
    
    # Extract face boundary (outer loop + holes)
    boundary = {
      outer_loop: [],
      holes: []
    }
    
    # Get outer loop vertices
    face.outer_loop.vertices.each do |vertex|
      world_point = vertex.position.transform(matrix)
      boundary[:outer_loop] << {
        x: world_point.x,
        y: world_point.y,
        z: world_point.z
      }
    end
    
    # Get holes (inner loops) - this is where windows/doors are handled
    if face.loops.length > 1
      face.loops[1..-1].each do |loop|
        hole = []
        loop.vertices.each do |vertex|
          world_point = vertex.position.transform(matrix)
          hole << {
            x: world_point.x,
            y: world_point.y,
            z: world_point.z
          }
        end
        boundary[:holes] << hole
      end
    end
    
    # Convert layout pieces to JSON format
    pieces = layout_pieces.map do |piece|
      {
        vertices: piece[:vertices].map { |pt| { x: pt.x, y: pt.y, z: pt.z } },
        thickness: piece[:thickness] || 0.1,
        material: piece[:material] || "default"
      }
    end
    
    # Create complete input JSON
    input_data = {
      boundary: boundary,
      layout_pieces: pieces,
      version: "1.0"
    }
    
    JSON.generate(input_data)
  end
  
  def self.parse_output_json(json_string)
    begin
      data = JSON.parse(json_string)
      trimmed_pieces = []
      
      if data["trimmed_pieces"]
        data["trimmed_pieces"].each do |piece_data|
          vertices = piece_data["vertices"].map do |v|
            Geom::Point3d.new(v["x"], v["y"], v["z"])
          end
          
          trimmed_pieces << {
            vertices: vertices,
            thickness: piece_data["thickness"],
            material: piece_data["material"]
          }
        end
      end
      
      return trimmed_pieces
      
    rescue JSON::ParserError => e
      puts "[PARAMETRIX] Failed to parse C++ engine output: #{e.message}"
      return []
    end
  end
  
  # Check if C++ engine is available
  def self.engine_available?
    File.exist?(ENGINE_PATH)
  end
  
  # Fallback to Ruby implementation if C++ engine not available
  def self.process_layout_with_fallback(face_data, layout_pieces)
    if engine_available?
      puts "[PARAMETRIX] Using C++ geometry engine for precise boolean operations"
      result = process_layout_with_cpp_engine(face_data, layout_pieces)
      return result if result
    end
    
    puts "[PARAMETRIX] C++ engine not available, falling back to Ruby implementation"
    # Fall back to existing Ruby trimming
    return process_layout_with_ruby_fallback(face_data, layout_pieces)
  end
  
  def self.process_layout_with_ruby_fallback(face_data, layout_pieces)
    # This would call your existing Ruby trimming logic
    # Essentially the current trimming_v3.rb functionality
    puts "[PARAMETRIX] Using Ruby fallback (limited boolean operations)"
    return layout_pieces # Return unmodified for now
  end

end