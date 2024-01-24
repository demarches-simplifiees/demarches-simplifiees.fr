redis_volatile_options = {
  url: ENV['REDIS_CACHE_URL'], # will fallback to default redis url if empty, and won't fail if there is no redis server
  ssl: ENV['REDIS_CACHE_SSL'] == 'enabled'
}
redis_volatile_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if ENV['REDIS_CACHE_SSL_VERIFY_NONE'] == 'enabled'

Kredis::Connections.connections[:volatile] = Redis.new(redis_volatile_options)
