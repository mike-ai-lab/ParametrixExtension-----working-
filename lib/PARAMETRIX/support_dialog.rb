# PARAMETRIX Support Dialog

module PARAMETRIX
  class SupportDialog
    
    def self.show
      html_content = generate_html
      
      dialog = UI::HtmlDialog.new(
        dialog_title: "Contact Support - Parametrix",
        preferences_key: "PARAMETRIX_Support_Dialog",
        scrollable: true,
        resizable: false,
        width: 450,
        height: 380,
        left: 200,
        top: 200,
        min_width: 450,
        min_height: 380,
        max_width: 450,
        max_height: 380,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      
      dialog.set_html(html_content)
      
      dialog.add_action_callback("send_support") do |action_context, params|
        name = params['name']
        subject = params['subject']
        message = params['message']
        
        if name.empty? || message.empty?
          dialog.execute_script("showError('Please fill in all required fields.')")
        else
          user_email = get_user_email_from_license
          success = send_support_request(name, user_email, subject, message)
          dialog.close
          if success
            UI.messagebox("Your email client has been opened with the support request. Please send the email to complete your request.", MB_OK, "Email Client Opened")
          else
            UI.messagebox("Failed to open email client. Please contact muhamad.shkeir@gmail.com directly.", MB_OK, "Email Client Error")
          end
        end
      end
      
      dialog.show
    end
    
    private
    
    def self.send_support_request(name, email, subject, message)
      begin
        # Try to find Outlook first
        outlook_path = nil
        ['C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE',
         'C:\\Program Files (x86)\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE',
         'C:\\Program Files\\Microsoft Office\\Office16\\OUTLOOK.EXE',
         'C:\\Program Files (x86)\\Microsoft Office\\Office16\\OUTLOOK.EXE'].each do |path|
          if File.exist?(path)
            outlook_path = path
            break
          end
        end
        
        if outlook_path
          # Launch Outlook directly with compose window
          to_email = "muhamad.shkeir@gmail.com"
          email_subject = "Parametrix Support: #{subject}"
          email_body = "From: #{name}\nUser Email: #{email || 'Not provided'}\n\nMessage:\n#{message}"
          
          cmd = "\"#{outlook_path}\" /c ipm.note /m \"#{to_email}?subject=#{email_subject}&body=#{email_body}\""
          system(cmd)
        else
          # Fallback: just show the message to copy
          full_message = "To: muhamad.shkeir@gmail.com\nSubject: Parametrix Support: #{subject}\n\nFrom: #{name}\nUser Email: #{email || 'Not provided'}\n\nMessage:\n#{message}"
          UI.messagebox("Please copy this message and send it manually:\n\n#{full_message}", MB_OK, "Copy and Send Manually")
        end
        
        return true
      rescue => e
        puts "[PARAMETRIX] Email error: #{e.message}"
        return false
      end
    end
    
    def self.get_user_info_from_license
      { name: 'Test User', email: 'test@example.com' }
    end
    
    def self.get_user_email_from_license
      get_user_info_from_license[:email]
    end
    
    def self.generate_html
      user_info = get_user_info_from_license
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
            .form-group {
              margin-bottom: 12px;
            }
            .form-group label {
              display: block;
              font-weight: 500;
              color: #555;
              margin-bottom: 4px;
              font-size: 13px;
            }
            .form-group input, .form-group textarea, .form-group select {
              width: 100%;
              padding: 8px;
              border: 1px solid #ccc;
              font-size: 13px;
              box-sizing: border-box;
            }
            .form-group textarea {
              height: 80px;
              resize: vertical;
            }
            .button-container {
              text-align: center;
              margin-top: 20px;
              padding-top: 15px;
              border-top: 1px solid #ddd;
            }
            .send-btn {
              background: #007bff;
              color: white;
              border: none;
              padding: 8px 20px;
              cursor: pointer;
              font-size: 13px;
            }
            .send-btn:hover {
              background: #0056b3;
            }
            .error {
              color: #dc3545;
              font-size: 12px;
              margin-top: 5px;
              display: none;
            }
            .required {
              color: #dc3545;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1 class="title">Contact Support</h1>
            </div>
            
            <form id="supportForm">
              <div class="form-group">
                <label for="name">Your Name <span class="required">*</span></label>
                <input type="text" id="name" name="name" value="#{user_info[:name]}" required>
              </div>
              
              <div class="form-group">
                <label for="subject">Subject</label>
                <select id="subject" name="subject">
                  <option value="General Inquiry">General Inquiry</option>
                  <option value="License Issue">License Issue</option>
                  <option value="Technical Support">Technical Support</option>
                  <option value="Bug Report">Bug Report</option>
                  <option value="Feature Request">Feature Request</option>
                </select>
              </div>
              
              <div class="form-group">
                <label for="message">Message <span class="required">*</span></label>
                <textarea id="message" name="message" placeholder="Please describe your issue or question..." required></textarea>
              </div>
              
              <div class="error" id="errorMessage"></div>
              
              <div class="button-container">
                <button type="button" class="send-btn" onclick="sendSupport()">Send Support Request</button>
              </div>
            </form>
          </div>
          
          <script>
            function sendSupport() {
              const name = document.getElementById('name').value.trim();
              const subject = document.getElementById('subject').value;
              const message = document.getElementById('message').value.trim();
              
              if (!name || !message) {
                showError('Please fill in all required fields.');
                return;
              }
              
              sketchup.send_support({
                name: name,
                subject: subject,
                message: message
              });
            }
            
            function showError(message) {
              const errorDiv = document.getElementById('errorMessage');
              errorDiv.textContent = message;
              errorDiv.style.display = 'block';
            }
          </script>
        </body>
        </html>
      HTML
    end
    
  end
end