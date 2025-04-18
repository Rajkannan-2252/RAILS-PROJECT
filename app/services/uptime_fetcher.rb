require 'net/http'
require 'json'

class UptimeFetcher
  UPTIME_URL = "http://192.168.210.74:3001/api/status-page/xaasio"

  def self.fetch_data
    uri = URI(UPTIME_URL)
    response = Net::HTTP.get(uri)
    JSON.parse(response) # Parse JSON response
  rescue => e
    Rails.logger.error "Error fetching uptime data: #{e.message}"
    nil
  end
end
