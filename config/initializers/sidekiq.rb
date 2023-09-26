if ENV.has_key?('REDIS_SIDEKIQ_SENTINELS')
  name = ENV.fetch('REDIS_SIDEKIQ_MASTER')
  username = ENV.fetch('REDIS_SIDEKIQ_USERNAME')
  password = ENV.fetch('REDIS_SIDEKIQ_PASSWORD')
  sentinels = ENV.fetch('REDIS_SIDEKIQ_SENTINELS')
    .split(',')
    .map { URI.parse(_1) }
    .map { { host: _1.host, port: _1.port, username:, password: } }

  Sidekiq.configure_server do |config|
    config.redis = {
      name:,
      sentinels:,
      username:,
      password:,
      role: :master
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      name:,
      sentinels:,
      username:,
      password:,
      role: :master
    }
  end
end
