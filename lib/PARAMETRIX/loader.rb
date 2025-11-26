# PARAMETRIX Loader
# Entry point and initialization logic - controls the loading order of all components

module PARAMETRIX
end

require File.join(__dir__, 'license_manager.rb')
require File.join(__dir__, 'core.rb')
require File.join(__dir__, 'preset_manager.rb')
require File.join(__dir__, 'multi_face_position.rb')
require File.join(__dir__, 'ui_dialog_newui.rb')
require File.join(__dir__, 'layout_engine.rb')
require File.join(__dir__, 'license_dialog.rb')
require File.join(__dir__, 'support_dialog.rb')
require File.join(__dir__, 'commands.rb')
require File.join(__dir__, 'toolbar.rb')