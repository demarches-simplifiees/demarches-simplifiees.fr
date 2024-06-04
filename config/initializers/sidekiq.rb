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

    if ENV['PROMETHEUS_EXPORTER_ENABLED'] == 'enabled'
      Yabeda.configure!
      Yabeda::Prometheus::Exporter.start_metrics_server!
    end

    if ENV['SKIP_RELIABLE_FETCH'].blank?
      Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
    end

    config.capsule('api_entreprise') do |cap|
      cap.concurrency = 1
      cap.queues = ['api_entreprise']
    end
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
