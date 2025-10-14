# frozen_string_literal: true

module Typhoeus
  module Cache
    # Cache successful Typhoeus requests in the Rails cache that are cacheable
    # according to their Cache-Control headers (only public + max-age >= 0).
    #
    # Usage:
    #   Typhoeus.config.cache = Typhoeus::Cache::SuccessfulRequestsRailsCache.new
    class SuccessfulRequestsRailsCache
      def get(request)
        return if request.options[:method] != :get

        ::Rails.cache.read(to_key(request))
      end

      def set(request, response)
        return if request.options[:method] != :get

        cache_info = CacheInfo.new(cache_controle_header(response))

        if response&.success? && cache_info.cacheable?
          ::Rails.cache.write(to_key(request), response, expires_in: cache_info.expires_in)
        end

      rescue => e
        Sentry.capture_exception(e, extra: { request: request.to_json })
      end

      private

      def to_key(request) = ActiveSupport::Cache.expand_cache_key(request, 'typhoeus')

      def cache_controle_header(resp) = Array.wrap(resp&.headers&.[]('cache-control')).join(', ')

      class CacheInfo
        attr_reader :expires_in

        MAX_AGE_LIMIT = 1.day.to_i

        def initialize(directives)
          directives = directives&.split(',')&.map(&:strip)&.map(&:downcase) || []

          @cacheable = CacheInfo.public?(directives)
          @expires_in = CacheInfo.expires_in(directives)
        end

        def cacheable? = @cacheable

        private

        def self.public?(directives)
          directives.include?('public') &&
            !directives.include?('no-store') &&
            !directives.include?('no-cache')
        end

        def self.expires_in(directives)
          duration = directives
            .find { it.start_with?('max-age=') }
            &.then { it.split('=').last.to_i } || 0

          duration.clamp(0, MAX_AGE_LIMIT)
        end
      end
    end
  end
end
