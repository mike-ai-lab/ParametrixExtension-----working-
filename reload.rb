# Complete hot reload of PARAMETRIX extension
EXT_ROOT = 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/'

# Remove all PARAMETRIX-related constants
ObjectSpace.each_object(Module) do |mod|
  name = mod.name rescue nil
  next unless name
  if name =~ /PARAMETRIX/i
    parent = Object
    parts = name.split("::")
    parts[0..-2].each do |p|
      break unless parent.const_defined?(p)
      parent = parent.const_get(p)
    end
    if parent.const_defined?(parts.last)
      parent.send(:remove_const, parts.last)
    end
  end
end

# Clear loaded feature cache
$LOADED_FEATURES.delete_if { |f| f =~ /parametrix/i }

# Remove plugin menu item if it existed
begin
  if defined?(@parametrix_menu) && @parametrix_menu.is_a?(UI::Command)
    UI.menu("Plugins").remove_item(@parametrix_menu)
  end
rescue Exception
end

# Remove observers only if they were stored globally
begin
  if defined?($parametrix_observers) && $parametrix_observers.is_a?(Array)
    $parametrix_observers.each do |obs|
      Sketchup.active_model.remove_observer(obs) rescue nil
    end
    $parametrix_observers.clear
  end
rescue Exception
end

# Reload fresh code
load File.join(EXT_ROOT, 'PARAMETRIX.rb')

puts "PARAMETRIX extension reloaded clean."
