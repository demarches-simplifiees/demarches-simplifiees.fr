# frozen_string_literal: true

redis_shared_options = {
  url: ENV['REDIS_CACHE_URL'], # will fallback to default redis url if empty, and won't fail if there is no redis server
  ssl: ENV['REDIS_CACHE_SSL'] == 'enabled',
  connect_timeout: 0.2
}
redis_shared_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if ENV['REDIS_CACHE_SSL_VERIFY_NONE'] == 'enabled'

Kredis::Connections.connections[:shared] = Redis.new(redis_shared_options)
