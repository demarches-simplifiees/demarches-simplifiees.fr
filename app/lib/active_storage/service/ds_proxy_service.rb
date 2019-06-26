module ActiveStorage
  # Wraps an ActiveStorage::Service to route direct upload and direct download URLs through our proxy,
  # thus avoiding exposing the storage provider’s URL to our end-users.
  class Service::DsProxyService < SimpleDelegator
    attr_reader :wrapped

    def self.build(wrapped:, configurator:, **options)
      new(wrapped: configurator.build(wrapped))
    end

    def initialize(wrapped:)
      @wrapped = wrapped
      super(wrapped)
    end

    def url(*args)
      url = wrapped.url(*args)
      publicize(url)
    end

    def url_for_direct_upload(*args)
      url = wrapped.url_for_direct_upload(*args)
      publicize(url)
    end

    private

    def object_for(key, &block)
      blob_url = url(key)
      if block_given?
        request = Typhoeus::Request.new(blob_url)
        request.on_headers do |response|
          if response.code != 200
            raise Fog::OpenStack::Storage::NotFound.new
          end
        end
        request.on_body do |chunk|
          yield chunk
        end
        request.run
      else
        response = Typhoeus.get(blob_url)
        if response.success?
          response
        else
          raise Fog::OpenStack::Storage::NotFound.new
        end
      end
    end

    def publicize(url)
      search = %r{^https://[^/]+/v1/AUTH_[a-f0-9]{32}}
      replace = 'https://static.demarches-simplifiees.fr'
      url.gsub(search, replace)
    end
  end
end
