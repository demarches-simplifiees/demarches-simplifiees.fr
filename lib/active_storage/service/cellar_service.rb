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
      # TODO: error handling
      if block_given?
        instrument :streaming_download, key: key do
          http_start do |http|
            http.request(get_request(key)) do |response|
              response.read_body do |chunk|
                yield(chunk.force_encoding(Encoding::BINARY))
              end
            end
          end
        end
      else
        instrument :download, key: key do
          http_start do |http|
            response = http.request(get_request(key))
            if response.is_a?(Net::HTTPSuccess)
              response.body.force_encoding(Encoding::BINARY)
            end
          end
        end
      end
    end

    def delete(key)
      # TODO: error handling
      instrument :delete, key: key do
        http_start do |http|
          perform_delete(http, key)
        end
      end
    end

    def delete_prefixed(prefix)
      # TODO: error handling
      # TODO: handle pagination if more than 1000 keys
      instrument :delete_prefixed, prefix: prefix do
        http_start do |http|
          list_prefixed(http, prefix).each do |key|
            # TODO: use bulk delete instead
            perform_delete(http, key)
          end
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

    def list_prefixed(http, prefix)
      request = Net::HTTP::Get.new(URI::join(@endpoint, "/?list-type=2&prefix=#{prefix}"))
      sign(request, "")
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        parse_bucket_listing(response.body)
      end
    end

    def parse_bucket_listing(bucket_listing_xml)
      doc = Nokogiri::XML(bucket_listing_xml)
      doc
        .xpath('//xmlns:Contents/xmlns:Key')
        .map{ |k| k.text }
    end

    def get_request(key)
      request = Net::HTTP::Get.new(URI::join(@endpoint, "/#{key}"))
      sign(request, key)
      request
    end

    def bulk_deletion_request_body(keys)
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Delete do
          xml.Quiet("true")
          keys.each do |k|
            xml.Object do
              xml.Key(k)
            end
          end
        end
      end
      builder.to_xml
    end

    def perform_delete(http, key)
      request = Net::HTTP::Delete.new(URI::join(@endpoint, "/#{key}"))
      sign(request, key)
      http.request(request)
    end
  end
end
