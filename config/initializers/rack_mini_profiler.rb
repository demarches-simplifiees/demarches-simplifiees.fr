if Rails.env.development?
  Rack::MiniProfiler.config.show_total_sql_count = true
end
