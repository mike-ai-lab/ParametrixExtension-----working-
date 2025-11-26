# Force reload PARAMETRIX with cache clearing
puts "[PARAMETRIX] Force reloading extension..."

# Clear any existing dialogs
if defined?(PARAMETRIX) && defined?(PARAMETRIX.class_variable_get(:@@current_dialog))
  begin
    dialog = PARAMETRIX.class_variable_get(:@@current_dialog)
    dialog.close if dialog && dialog.visible?
  rescue
  end
end

# Unload existing module
Object.send(:remove_const, :PARAMETRIX) if defined?(PARAMETRIX)

# Force reload all files
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/PARAMETRIX.rb'

puts "[PARAMETRIX] Extension reloaded with cache cleared!"
puts "[PARAMETRIX] Version: v1.1-THICKNESS with randomize thickness feature"