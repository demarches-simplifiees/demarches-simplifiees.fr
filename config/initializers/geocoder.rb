# frozen_string_literal: true

cache_configuration = if Rails.cache.respond_to?(:redis)
  { cache: Rails.cache.redis, cache_options: { prefix: "geocoder:", expiration: 6.hours } }
else
  { cache: Geocoder::CacheStore::Generic.new(Rails.cache, { prefix: "geocoder:" }) } # generic uses default Rails.cache expiration as of geocoder 1.8
end

Geocoder.configure(lookup: :ban_data_gouv_fr, use_https: true, **cache_configuration)
