cache_configuration = if ENV['REDIS_CACHE_URL'].present?
  { cache: Redis.new(url: ENV['REDIS_CACHE_URL']), cache_options: { prefix: "geocoder:", expiration: 6.hours } }
else
  { cache: Geocoder::CacheStore::Generic.new(Rails.cache, { prefix: "geocoder:" }) } # generic has no specific expiration support as of geocoder 1.8
end

Geocoder.configure(lookup: :ban_data_gouv_fr, use_https: true, **cache_configuration)
