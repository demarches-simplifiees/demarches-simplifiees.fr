require 'base64'
require 'net/http'
require 'openssl'

module ActiveStorage
  class Service::CellarService < Service
    def initialize(access_key_id:, secret_access_key:, bucket:, **)
      @endpoint = URI::HTTPS.build(host: "#{bucket}.cellar.services.clever-cloud.com")
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket = bucket
    end

    def download(key)
      instrument :download, key: key do
        http_start do |http|
          request = Net::HTTP::Get.new(URI::join(@endpoint, "/#{key}"))
          sign(request, key)
          response = http.request(request)
          if response.is_a?(Net::HTTPSuccess)
            response.body
          end
        end
      end
    end

    def delete(key)
      instrument :delete, key: key do
        http_start do |http|
          request = Net::HTTP::Delete.new(URI::join(@endpoint, "/#{key}"))
          sign(request, key)
          http.request(request)
        end
      end
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

    def http_start(&block)
      Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: true, &block)
    end

    def sign(request, key, checksum: '')
      date = Time.now.httpdate
      sig = signature(method: request.method, key: key, date: date, checksum: checksum)
      request['date'] = date
      request['authorization'] = "AWS #{@access_key_id}:#{sig}"
    end

    def presigned_url(method:, key:, expires_in:, content_type: '', checksum: '', **query_params)
      expires = expires_in.from_now.to_i

      query = query_params.merge({
        AWSAccessKeyId: @access_key_id,
        Expires: expires,
        Signature: signature(method: method, key: key, expires: expires, content_type: content_type, checksum: checksum)
      })

      generated_url = URI::join(@endpoint, "/#{key}","?#{query.to_query}").to_s
    end

    def signature(method:, key:, expires: '', date: '', content_type: '', checksum: '')
      canonicalized_amz_headers = ""
      canonicalized_resource = "/#{@bucket}/#{key}"
      string_to_sign = "#{method}\n#{checksum}\n#{content_type}\n#{expires}#{date}\n" +
                       "#{canonicalized_amz_headers}#{canonicalized_resource}"
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @secret_access_key, string_to_sign)).strip
    end
  end
end
