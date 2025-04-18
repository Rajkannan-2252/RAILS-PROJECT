# app/services/uptime_kuma_service.rb
require 'net/http'
require 'json'

class UptimeKumaService
  def initialize(base_url = 'http://192.168.210.74:3001')
    @base_url = base_url
  end
  
  def get_status_page(status_id = 'xaasio')
    uri = URI.parse("#{@base_url}/api/status-page/#{status_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    
    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      nil
    end
  rescue => e
    Rails.logger.error "Error fetching Uptime Kuma status: #{e.message}"
    nil
  end
  
  def get_heartbeat(status_id = 'xaasio')
    uri = URI.parse("#{@base_url}/api/status-page/heartbeat/#{status_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    
    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      nil
    end
  rescue => e
    Rails.logger.error "Error fetching Uptime Kuma heartbeat: #{e.message}"
    nil
  end
end