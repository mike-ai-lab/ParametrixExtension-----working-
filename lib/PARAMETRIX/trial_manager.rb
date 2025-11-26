# PARAMETRIX Trial Management
# Handles trial countdown and status display

module PARAMETRIX
  module TrialManager
    
    class << self
      
      # Get remaining trial days
      def get_trial_days_remaining
        license_file = File.join(ENV['APPDATA'], 'PARAMETRIX', 'license.jwt')
        return 0 unless File.exist?(license_file)
        
        begin
          trial_data = JSON.parse(Base64.decode64(File.read(license_file)))
          trial_end = trial_data['trial_end']
          return 0 unless trial_end
          
          remaining_seconds = trial_end - Time.now.to_i
          remaining_days = (remaining_seconds / (24 * 60 * 60)).ceil
          
          return [remaining_days, 0].max
        rescue
          return 0
        end
      end
      
      # Start trial countdown display
      def start_trial_countdown
        days_remaining = get_trial_days_remaining
        
        if days_remaining > 0
          UI.start_timer(5.0, true) do
            update_trial_status
          end
        end
      end
      
      # Update trial status display
      def update_trial_status
        days_remaining = get_trial_days_remaining
        
        if days_remaining <= 0
          show_trial_expired
          return false # Stop timer
        end
        
        # Update status bar
        Sketchup.status_text = "PARAMETRIX Trial: #{days_remaining} days remaining"
        
        # Show warning when trial is about to expire
        if days_remaining <= 2 && !@trial_warning_shown
          UI.messagebox(
            "Your PARAMETRIX trial expires in #{days_remaining} days.\n\nPurchase a full license to continue using PARAMETRIX.\n\nVisit: www.parametrix.com",
            MB_OK,
            "Trial Expiring Soon"
          )
          @trial_warning_shown = true
        end
        
        return true # Continue timer
      end
      
      # Show trial expired message
      def show_trial_expired
        result = UI.messagebox(
          "Your PARAMETRIX trial has expired.\n\nWould you like to purchase a full license?",
          MB_YESNO,
          "Trial Expired"
        )
        
        if result == IDYES
          UI.messagebox(
            "Purchase PARAMETRIX Full License\n\nVisit: www.parametrix.com\nEmail: sales@parametrix.com",
            MB_OK,
            "Purchase License"
          )
        end
        
        # Remove expired trial file
        license_file = File.join(ENV['APPDATA'], 'PARAMETRIX', 'license.jwt')
        File.delete(license_file) if File.exist?(license_file)
      end
      
      # Check if trial is active
      def trial_active?
        get_trial_days_remaining > 0
      end
      
    end
  end
end