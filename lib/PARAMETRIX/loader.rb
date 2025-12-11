# PARAMETRIX Loader
# Entry point and initialization logic - controls the loading order of all components

module PARAMETRIX
end

load File.join(__dir__, 'core.rb')
load File.join(__dir__, 'preset_manager.rb')
load File.join(__dir__, 'multi_face_position.rb')
load File.join(__dir__, 'trimming_v4_enhanced.rb')
load File.join(__dir__, 'layout_engine.rb')
load File.join(__dir__, 'ui_dialog_newui.rb')
load File.join(__dir__, 'license_manager.rb')
load File.join(__dir__, 'license_dialog.rb')
load File.join(__dir__, 'support_dialog.rb')
load File.join(__dir__, 'commands.rb')
load File.join(__dir__, 'toolbar.rb')