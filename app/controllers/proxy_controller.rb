require 'net/http'
require 'uri'

class ProxyController < ApplicationController
  # Skip CSRF protection for the proxy
  skip_before_action :verify_authenticity_token
  
  def index
    # Simple approach - create a direct iframe with no proxy
    # This is an alternative if the proxy approach is too complex
    render inline: <<-HTML
      <html>
      <head>
        <title>XaasIO Application</title>
        <style>
          body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; }
          iframe { width: 100%; height: 100%; border: none; }
        </style>
      </head>
      <body>
        <iframe src="https://192.168.210.82/" allowfullscreen></iframe>
      </body>
      </html>
    HTML
  end
  
  # The commented out proxy implementation below would be the more robust solution
  # but requires more testing
  
  def proxy_approach
    # The target base URL to proxy
    target_base_url = "https://192.168.210.82"
    
    # Get the path from the request
    path = params[:path] || ""
    
    # Construct the full target URL
    target_url = "#{target_base_url}/#{path}"
    target_url = target_url.chomp('/') if path.blank?
    
    # Add query parameters if present
    target_url += "?#{request.query_string}" if request.query_string.present?
    
    begin
      # Parse the URL
      uri = URI.parse(target_url)
      
      # Create a new HTTP connection
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for internal use
      http.open_timeout = 5 # 5 second connection timeout
      http.read_timeout = 30 # 30 second read timeout
      
      # Create the request based on the HTTP method
      proxy_request = create_request(uri)
      
      # Copy headers from original request
      copy_request_headers(proxy_request)
      
      # Copy cookies from original request
      proxy_request['Cookie'] = request.headers['Cookie'] if request.headers['Cookie'].present?
      
      # Copy body for POST, PUT, PATCH requests
      if ['POST', 'PUT', 'PATCH'].include?(request.method)
        # Get the raw post data
        if request.raw_post.present?
          proxy_request.body = request.raw_post
          proxy_request.content_type = request.content_type if request.content_type.present?
        end
      end
      
      # Make the request
      response = http.request(proxy_request)
      
      # Process the response
      process_response(response)
    rescue => e
      render plain: "Proxy Error: #{e.message}", status: 500
    end
  end
  
  private
  
  def create_request(uri)
    case request.method
    when 'GET'
      Net::HTTP::Get.new(uri.request_uri)
    when 'POST'
      Net::HTTP::Post.new(uri.request_uri)
    when 'PUT'
      Net::HTTP::Put.new(uri.request_uri)
    when 'DELETE'
      Net::HTTP::Delete.new(uri.request_uri)
    when 'PATCH'
      Net::HTTP::Patch.new(uri.request_uri)
    when 'HEAD'
      Net::HTTP::Head.new(uri.request_uri)
    else
      Net::HTTP::Get.new(uri.request_uri)
    end
  end
  
  def copy_request_headers(proxy_request)
    request.headers.each do |name, value|
      next if name.to_s.downcase.start_with?('action_') # Skip Rails internal headers
      next if FILTERED_REQUEST_HEADERS.include?(name.downcase)
      proxy_request[name] = value unless name.to_s.downcase == 'host'
    end
    
    # Set custom headers
    proxy_request['Host'] = URI.parse("https://192.168.210.82").host
    proxy_request['X-Forwarded-For'] = request.remote_ip
    proxy_request['User-Agent'] = request.user_agent || 'Ruby Proxy'
    proxy_request['Accept-Encoding'] = 'identity' # Avoid compression issues
  end
  
  def process_response(response)
    # Copy response status
    status = response.code.to_i
    
    # Setup response headers
    headers = {}
    response.each_header do |name, value|
      # Skip headers that would restrict iframe embedding
      next if name.downcase == 'x-frame-options'
      next if name.downcase == 'content-security-policy'
      # Skip transfer-encoding as it's handled by Rails
      next if name.downcase == 'transfer-encoding'
      headers[name] = value
    end
    
    # Allow iframe embedding
    headers['X-Frame-Options'] = 'ALLOWALL'
    headers['Content-Security-Policy'] = "frame-ancestors 'self' *"
    
    # Copy cookies from the response
    if response['Set-Cookie']
      headers['Set-Cookie'] = response['Set-Cookie']
    end
    
    # Determine content type
    content_type = response.content_type || 'text/html'
    
    # Apply headers to our Rails response
    headers.each do |name, value|
      self.response.headers[name] = value
    end
    
    # Send the response
    render body: response.body, status: status, content_type: content_type
  end
  
  # Headers that shouldn't be copied to the proxy request
  FILTERED_REQUEST_HEADERS = [
    'host',
    'connection',
    'content-length',
    'accept-encoding'
  ]
end