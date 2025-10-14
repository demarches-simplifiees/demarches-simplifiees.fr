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
        ::Rails.cache.read(request)
      end

      def set(request, response)
        cache_info = CacheInfo.new(cache_controle_header(response))

        if response&.success? && cache_info.cacheable?
          ::Rails.cache.write(request, response, expires_in: cache_info.expires_in)
        end
      end

      private

      def cache_controle_header(resp) = Array.wrap(resp&.headers&.[]('cache-control')).join(', ')

      class CacheInfo
        attr_reader :expires_in

        def initialize(directives)
          directives = directives&.split(',')&.map(&:strip)&.map(&:downcase) || []

          @cacheable = CacheInfo.public?(directives)
          @expires_in = CacheInfo.expires_in(directives)
        end

        def cacheable? = @cacheable

        def self.public?(directives)
          directives.include?('public') &&
            !directives.include?('no-store') &&
            !directives.include?('no-cache')
        end

        def self.expires_in(directives)
          directives
            .find { it.start_with?('max-age=') }
            &.then { it.split('=').last.to_i } || 0
        end
      end
    end
  end
end
