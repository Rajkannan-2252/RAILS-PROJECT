class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Allow CORS for embedding the application
  before_action :set_cors_headers
  
  private
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def iframe_test
    render inline: <<-HTML
      <!DOCTYPE html>
      <html>
      <head><title>iFrame Test</title></head>
      <body>
        <h1>iFrame Test</h1>
        
        <!-- Test with absolute URL -->
        <h2>Direct iframe (absolute URL):</h2>
        <iframe src="https://192.168.210.74:3001/status/xaasio" width="100%" height="300px"></iframe>
        
        <!-- Show what URL is actually being loaded -->
        <h2>Current iframe src:</h2>
        <p id="iframe-src"></p>
        
        <script>
          // Display the actual URL the iframe is trying to load
          document.getElementById('iframe-src').textContent = 
            document.querySelector('iframe').src;
        </script>
      </body>
      </html>
    HTML
  end
end
