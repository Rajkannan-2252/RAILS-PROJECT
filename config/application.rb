require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module InternalCompany
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # Set Sidekiq as the Active Job queue adapter
    config.active_job.queue_adapter = :sidekiq

    config.action_dispatch.default_headers.merge!(
      'X-Frame-Options' => 'ALLOWALL'
    )
  end
end
