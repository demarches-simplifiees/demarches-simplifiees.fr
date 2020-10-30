if Rails.env.development?
  Rack::MiniProfiler.config.authorization_mode = :whitelist
end
