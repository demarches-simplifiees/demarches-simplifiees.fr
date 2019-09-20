module ActiveStorage
  # Wraps an ActiveStorage::Service to route direct upload and direct download URLs through our proxy,
  # thus avoiding exposing the storage provider’s URL to our end-users. It also overrides upload and
  # object_for methods to fetch and put blobs through encryption proxy.
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

    # This method is responsible for writing to object storage. We directly use direct upload
    # url to ensure we upload through encryption proxy.
    def upload(key, io, checksum: nil, **)
      wrapped.send(:instrument, :upload, key: key, checksum: checksum) do
        url = url_for_direct_upload(key, expires_in: 1.hour)
        data = Fog::Storage.parse_data(io)

        headers = { 'Content-Type' => wrapped.send(:guess_content_type, io) }.merge(data[:headers])
        if checksum
          headers['ETag'] = wrapped.send(:convert_base64digest_to_hexdigest, checksum)
        end

        response = Typhoeus::Request.new(
          url,
          method: :put,
          body: data[:body].read,
          headers: headers
        ).run

        if response.success?
          response
        else
          raise ActiveStorage::IntegrityError
        end
      end
    end

    private

    # This method is responsible for reading from object storage. We use url method
    # on the service to ensure we download through encryption proxy.
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
