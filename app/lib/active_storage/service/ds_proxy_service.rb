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

    def publicize(url)
      search = %r{^https://[^/]+/v1/AUTH_[a-f0-9]{32}}
      replace = "https://#{ENV['APP_HOST']}/direct-upload"
      url.gsub(search, replace)
    end
  end
end
