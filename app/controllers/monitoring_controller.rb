# app/controllers/monitoring_controller.rb
class MonitoringController < ApplicationController
  def index
    service = UptimeKumaService.new
    @status_data = service.get_status_page
    @heartbeat_data = service.get_heartbeat
    
    # Debug heartbeat data
    Rails.logger.debug "Heartbeat data: #{@heartbeat_data.inspect}"
    if @heartbeat_data && @heartbeat_data['heartbeatList']
      @heartbeat_data['heartbeatList'].each do |id, heartbeats|
        last_status = heartbeats.last&.dig('status')
        Rails.logger.debug "Monitor #{id} last status: #{last_status}"
      end
    end
    
    # Process the data to combine status and heartbeat information
    if @status_data && @heartbeat_data
      process_monitor_data
    end
  end
  
  private
  def process_monitor_data
    return unless @status_data && @status_data['publicGroupList'] && @heartbeat_data
    
    # Map the uptime data from heartbeat to the monitors
    uptime_data = @heartbeat_data['uptimeList'] || {}
    heartbeat_list = @heartbeat_data['heartbeatList'] || {}
    
    @status_data['publicGroupList'].each do |group|
      group['monitorList'].each do |monitor|
        # Find corresponding uptime data (assuming monitor has an id that matches the key in uptimeList)
        monitor_id = monitor['id'].to_s
        
        # Add the uptime percentage from the heartbeat data
        uptime_key = "#{monitor_id}_24" # Format from your example JSON
        monitor['uptime'] = uptime_data[uptime_key] ? (uptime_data[uptime_key] * 100).round(2) : nil
        
        # Set heartbeat list if available
        if heartbeat_list[monitor_id]
          monitor['heartbeatList'] = heartbeat_list[monitor_id]
          
          # Check the last few heartbeats to determine current status
          recent_heartbeats = heartbeat_list[monitor_id].last(5) # Check last 5 entries
          if recent_heartbeats.any? { |hb| hb['status'].to_i == 0 }
            monitor['current_status'] = 'down' # At least one recent heartbeat shows down
          else
            monitor['current_status'] = 'up'
          end
        end
      end
    end
  end
  
end