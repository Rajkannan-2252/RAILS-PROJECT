# app/controllers/embedded_controller.rb
class EmbeddedController < ApplicationController
    def uptime_kuma
    end
    
    def uptime_proxy
      require 'net/http'
      
      uri = URI.parse("https://192.168.210.74:3001/status/xaasio")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      
      response = http.request(request)
      
      if response.code.to_i == 200
        # Remove headers that prevent embedding
        response_headers = {}
        response.each_header do |key, value|
          next if ['x-frame-options', 'content-security-policy'].include?(key.downcase)
          response_headers[key] = value
        end
        
        render html: response.body.html_safe, layout: false, status: response.code.to_i, headers: response_headers
      else
        render html: "<p>Error accessing status page</p>".html_safe, status: 500
      end
    end
  end