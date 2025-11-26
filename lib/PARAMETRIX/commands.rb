# PARAMETRIX Commands

module PARAMETRIX

  PARAMETRIX_COMMANDS_VERSION = "PARAMETRIX_RELEASE_1.0"

  def self.start_layout_process
    model = Sketchup.active_model
    selection = model.selection

    if selection.empty?
      UI.messagebox("Please select one or more faces to create layout.")
      return
    end

    faces_data = PARAMETRIX.analyze_multi_face_selection(selection)

    if faces_data.empty?
      UI.messagebox("No valid faces found in selection.", "PARAMETRIX")
      return
    end

    unless PARAMETRIX.validate_faces_for_processing(faces_data)
      UI.messagebox("Selected faces are not suitable for processing.")
      return
    end

    multi_face_position = CladzPARAMETRIXMultiFacePosition.new

    faces_data.each do |data|
      multi_face_position.add_face(data[:face], data[:matrix])
    end

    PARAMETRIX.show_html_dialog(multi_face_position)
  end

  def self.show_license_info
    PARAMETRIX::LicenseDialog.show
  end

  def self.check_for_updates
    UI.messagebox("Update checking functionality will be implemented in a future version.", MB_OK, "Check for Updates")
  end

  def self.contact_support
    PARAMETRIX::SupportDialog.show
  end

end