Rails.application.configure do
  config.enable_reloading = false # in-memory store must survive between requests
  config.eager_load = false
  config.consider_all_requests_local = true
end
