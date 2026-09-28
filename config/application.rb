require_relative "boot"

require "rails"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module RideHailing
  # API-only Rails app. There is deliberately no ActiveRecord: storage is
  # in-memory (see app/repositories) and the domain is plain Ruby objects.
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
  end
end
