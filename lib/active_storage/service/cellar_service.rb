require 'base64'
require 'openssl'
require 'uri'

module ActiveStorage
  class Service::CellarService < Service
    def initialize(access_key_id:, secret_access_key:, bucket:, **)
      @endpoint = URI::HTTPS.build(host: "#{bucket}.cellar.services.clever-cloud.com")
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket = bucket
    end

    def url(key, expires_in:, filename:, disposition:, content_type:)
      instrument :url, key: key do |payload|
        generated_url = presigned_url(
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
        generated_url = presigned_url(
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

    private

    def presigned_url(method:, key:, expires_in:, content_type: '', checksum: '', **query_params)
      expires = expires_in.from_now.to_i

      query = query_params.merge({
        AWSAccessKeyId: @access_key_id,
        Expires: expires,
        Signature: signature(method: method, key: key, expires: expires, content_type: content_type, checksum: checksum)
      })

      generated_url = URI::join(@endpoint, "/#{key}","?#{query.to_query}").to_s
    end

    def signature(method:, key:, expires:, content_type: '', checksum: '')
      canonicalized_amz_headers = ""
      canonicalized_resource = "/#{@bucket}/#{key}"
      string_to_sign = "#{method}\n#{checksum}\n#{content_type}\n#{expires}\n" +
                       "#{canonicalized_amz_headers}#{canonicalized_resource}"
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @secret_access_key, string_to_sign)).strip
    end
  end
end
