module ActiveStorage
  class Service::CellarService < Service
    def initialize(access_key_id:, secret_access_key:, bucket:, **)
      @adapter = Cellar::CellarAdapter.new(access_key_id, secret_access_key, bucket)
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        @adapter.session { |s| s.upload(key, io, checksum) }
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          @adapter.session { |s| s.download(key, &block) }
        end
      else
        instrument :download, key: key do
          @adapter.session { |s| s.download(key) }
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        @adapter.session { |s| s.download(key, range: range) }
      end
    end

    def delete(key)
      instrument :delete, key: key do
        @adapter.session { |s| s.delete(key) }
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        @adapter.session do |s|
          keys = s.list_prefixed(prefix)
          s.delete_keys(keys)
        end
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = @adapter.session { |s| s.exist?(key) }
        payload[:exist] = answer
        answer
      end
    end

    def url(key, expires_in:, filename:, disposition:, content_type:)
      instrument :url, key: key do |payload|
        generated_url = @adapter.presigned_url(
          method: 'GET',
          key: key,
          expires_in: expires_in,
          "response-content-disposition": content_disposition_with(type: disposition, filename: filename),
          "response-content-type": content_type
        )
        payload[:url] = generated_url
        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        generated_url = @adapter.presigned_url(
          method: 'PUT',
          key: key,
          expires_in: expires_in,
          content_type: content_type,
          checksum: checksum
        )
        payload[:url] = generated_url
        generated_url
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      { "Content-Type" => content_type, "Content-MD5" => checksum }
    end
  end
end
