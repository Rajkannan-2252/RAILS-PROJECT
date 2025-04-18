Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "http://192.168.210.74:3001/status/xaasio"
    policy.object_src  :none

    # Allow scripts and styles from the uptime service
    policy.script_src  :self, :https, "http://192.168.210.74:3001/status/xaasio", "'unsafe-inline'", "'unsafe-eval'"
    policy.style_src   :self, :https, "http://192.168.210.74:3001/status/xaasio", "'unsafe-inline'"


    # Allow embedding frames from uptime service
    policy.frame_src :self, "http://192.168.210.74:3001/status/xaasio"

    # Allow your Rails app to be embedded in iframes by the uptime service
    policy.frame_ancestors :self, "http://192.168.210.74:3001/status/xaasio"

    # Allow API calls and WebSockets from uptime service
    policy.connect_src :self, :https, "ws://192.168.210.74:3001/status/xaasio", "wss://192.168.210.74:3001/status/xaasio", "http://192.168.210.74:3001/status/xaasio"
  end

  # Set default headers to explicitly allow iframes
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'ALLOWALL'
  }

  # Set to report-only mode for debugging (remove this in production)
  config.content_security_policy_report_only = true
end
