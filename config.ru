# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if ENV['PROMETHEUS_EXPORTER_ENABLED'] == 'enabled'
  Yabeda::Prometheus::Exporter.start_metrics_server!
end

run Rails.application
Rails.application.load_server
