# PARAMETRIX License Information Dialog

module PARAMETRIX
  class LicenseDialog
    
    def self.show
      license_info = get_license_info
      
      html_content = generate_html(license_info)
      
      dialog = UI::HtmlDialog.new(
        dialog_title: "PARAMETRIX License Information",
        preferences_key: "PARAMETRIX_License_Dialog",
        scrollable: true,
        resizable: false,
        width: 450,
        height: 400,
        left: 200,
        top: 200,
        min_width: 450,
        min_height: 400,
        max_width: 450,
        max_height: 400,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      
      dialog.set_html(html_content)
      
      dialog.add_action_callback("remove_license") do |action_context|
        result = UI.messagebox(
          "Are you sure you want to remove the current license?\n\nThis will require re-activation to use the extension.",
          MB_YESNO,
          "Remove License"
        )
        if result == IDYES
          remove_license
          dialog.close
          UI.messagebox("License removed successfully. Please restart SketchUp to re-activate.", MB_OK, "License Removed")
        end
      end
      
      dialog.add_action_callback("purchase_license") do |action_context|
        UI.openURL("mailto:muhamad.shkeir@gmail.com?subject=Parametrix License Purchase")
      end
      
      dialog.show
    end
    
    private
    
    def self.get_license_info
      info = {
        extension_name: "Parametrix",
        version: "V 2.7",
        status: "Unknown",
        days_remaining: "N/A",
        licensed_by: "PARAMETRIX Development Team",
        licensed_to: "N/A",
        user_name: "N/A"
      }
      
      info[:status] = "Licensed"
      info[:licensed_to] = "Test User"
      info[:user_name] = "Test User"
      info[:is_trial] = false
      info[:days_remaining] = "-"
      
      info
    end
    
    def self.remove_license
      # Stub - no action needed
    end
    
    def self.generate_html(info)
      is_trial = info[:status] == 'trial'
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              margin: 0;
              padding: 15px;
              background: #f5f5f5;
              color: #333;
            }
            .container {
              background: white;
              border: 1px solid #ccc;
              padding: 20px;
              max-width: 400px;
              margin: 0 auto;
            }
            .header {
              text-align: center;
              margin-bottom: 20px;
              padding-bottom: 10px;
              border-bottom: 1px solid #ddd;
            }
            .title {
              font-size: 18px;
              font-weight: 600;
              color: #333;
              margin: 0;
            }
            .info-row {
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 6px 0;
              border-bottom: 1px solid #f0f0f0;
            }
            .info-row:last-of-type {
              border-bottom: none;
            }
            .label {
              font-weight: 500;
              color: #555;
              font-size: 13px;
            }
            .value {
              font-weight: 400;
              color: #333;
              font-size: 13px;
              text-align: right;
            }
            .status-container {
              display: flex;
              gap: 10px;
              align-items: center;
            }
            .status-badge {
              padding: 4px 12px;
              border-radius: 4px;
              font-size: 12px;
              font-weight: 500;
              border: 1px solid #ddd;
              background: #f8f9fa;
              color: #666;
            }
            .status-badge.active {
              background: #d4edda;
              border-color: #c3e6cb;
              color: #155724;
            }
            .purchase-btn {
              background: #007bff;
              color: white;
              border: none;
              padding: 4px 8px;
              border-radius: 3px;
              cursor: pointer;
              font-size: 11px;
              margin-left: 5px;
            }
            .purchase-btn:hover {
              background: #0056b3;
            }
            .button-container {
              text-align: center;
              margin-top: 20px;
              padding-top: 15px;
              border-top: 1px solid #ddd;
            }
            .remove-btn {
              background: #dc3545;
              color: white;
              border: none;
              padding: 8px 16px;
              border-radius: 4px;
              cursor: pointer;
              font-size: 13px;
            }
            .remove-btn:hover {
              background: #c82333;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1 class="title">License Information</h1>
            </div>
            
            <div class="info-row">
              <span class="label">Extension:</span>
              <span class="value">#{info[:extension_name]}</span>
            </div>
            
            <div class="info-row">
              <span class="label">Version:</span>
              <span class="value">#{info[:version]}</span>
            </div>
            
            <div class="info-row">
              <span class="label">Status:</span>
              <div class="status-container">
                <span class="status-badge #{is_trial ? '' : 'active'}">Licensed</span>
                <span class="status-badge #{is_trial ? 'active' : ''}">Free Trial</span>
                #{is_trial ? '<button class="purchase-btn" onclick="sketchup.purchase_license()">Purchase</button>' : ''}
              </div>
            </div>
            
            <div class="info-row">
              <span class="label">Days Remaining:</span>
              <span class="value">#{info[:days_remaining]}</span>
            </div>
            
            <div class="info-row">
              <span class="label">Licensed By:</span>
              <span class="value">#{info[:licensed_by]}</span>
            </div>
            
            <div class="info-row">
              <span class="label">Licensed To:</span>
              <span class="value">#{info[:user_name] != 'N/A' ? info[:user_name] : info[:licensed_to]}</span>
            </div>
            
            <div class="button-container">
              <button class="remove-btn" onclick="sketchup.remove_license()">Remove License</button>
            </div>
          </div>
        </body>
        </html>
      HTML
    end
    
    def self.get_status_class(status)
      case status.downcase
      when 'licensed', 'active'
        'status-active'
      when 'trial', 'free trial'
        'status-trial'
      else
        'status-invalid'
      end
    end
    
  end
end