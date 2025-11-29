# AutoOpenTrim_projected_console_safe.rb
model     = Sketchup.active_model
entities  = model.active_entities
sel       = model.selection

def solid_obj?(obj)
  (obj.is_a?(Sketchup::Group) || obj.is_a?(Sketchup::ComponentInstance)) && obj.manifold?
end

if sel.length != 2
  UI.messagebox("Select exactly two items: solid group/component + face.")
else
  solid_obj    = sel.find { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
  opening_face = sel.find { |e| e.is_a?(Sketchup::Face) }

  if solid_obj && opening_face
    model.start_operation("Auto Open Trim", true)
    begin
      temp_group = entities.add_group
      temp_ent   = temp_group.entities

      pts = opening_face.vertices.map(&:position)
      temp_face = temp_ent.add_face(pts)

      if temp_face
        normal = opening_face.normal
        normal = Geom::Vector3d.new(0,0,1) if normal.length == 0
        normal = normal.normalize

        depth = 10_000.mm
        temp_face.pushpull(depth, true)

        if solid_obj?(solid_obj)
          result = nil
          begin
            result = temp_group.trim(solid_obj)
          rescue
            result = nil
          end

          if !result && solid_obj.is_a?(Sketchup::Group)
            begin
              result = solid_obj.trim(temp_group)
            rescue
              result = nil
            end
          end

          temp_group.erase! if temp_group.valid? && !temp_group.deleted?
          model.commit_operation
          UI.messagebox("Trimming completed. If nothing removed, the face did not intersect the solid.")
        else
          model.abort_operation
          UI.messagebox("Selected layout is not a watertight solid.")
        end
      else
        model.abort_operation
        UI.messagebox("Face duplication failed.")
      end

    rescue => err
      model.abort_operation
      UI.messagebox("Error: #{err.message}")
    end

  else
    UI.messagebox("Selection must include a solid group/component and a face.")
  end
end
