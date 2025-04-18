# app/jobs/fetch_uptime_data_job.rb
class FetchUptimeDataJob < ApplicationJob
    queue_as :default
  
    def perform
      service = UptimeKumaService.new
      status_data = service.get_status_page
      
      # Store this data in your database
      # This is just example code - adjust to your actual models
      if status_data && status_data['publicGroupList'].present?
        status_data['publicGroupList'].each do |group|
          if group['monitorList'].present?
            group['monitorList'].each do |monitor|
              MonitorStatus.find_or_initialize_by(monitor_id: monitor['id']).update(
                name: monitor['name'],
                uptime: monitor['uptime'] || 100.0,
                active: monitor['active'] || true,
                last_checked: Time.now
              )
            end
          end
        end
      end
    end
  end