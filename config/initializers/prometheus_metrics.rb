if ENV['PROMETHEUS_EXPORTER_ENABLED'] == 'enabled' && !Sidekiq.server?
  Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: Rails.root.join('tmp', 'prometheus'))
end
