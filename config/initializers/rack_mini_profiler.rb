# frozen_string_literal: true

if Rails.env.development?
  Rack::MiniProfiler.config.show_total_sql_count = true
  Rack::MiniProfiler.config.skip_paths = [/vite-dev.*/]
end
