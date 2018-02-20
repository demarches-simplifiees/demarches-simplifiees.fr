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

    def upload(key, io, checksum: nil)
      instrument :upload, key: key, checksum: checksum do
        with_io_length(io) do |io, length|
          http_start do |http|
            request = Net::HTTP::Put.new(URI::join(@endpoint, "/#{key}"))
            request.content_type = 'application/octet-stream'
            request['Content-MD5'] = checksum
            request['Content-Length'] = length
            sign(request, key, checksum: checksum)
            request.body_stream = io
            http.request(request)
            # TODO: error handling
          end
        end
      end
    end

    def download(key)
      if block_given?
        instrument :streaming_download, key: key do
          http_start do |http|
            http.request(get_request(key)) do |response|
              if response.is_a?(Net::HTTPSuccess)
                response.read_body do |chunk|
                  yield(chunk.force_encoding(Encoding::BINARY))
                end
              else
                # TODO: error handling
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
            else
              # TODO: error handling
            end
          end
        end
      end
    end

    def delete(key)
      # TODO: error handling
      instrument :delete, key: key do
        http_start do |http|
          request = Net::HTTP::Delete.new(URI::join(@endpoint, "/#{key}"))
          sign(request, key)
          http.request(request)
        end
      end
    end

    def delete_prefixed(prefix)
      # TODO: error handling
      # TODO: handle pagination if more than 1000 keys
      instrument :delete_prefixed, prefix: prefix do
        http_start do |http|
          keys = list_prefixed(http, prefix)
          request_body = bulk_deletion_request_body(keys)
          checksum = Digest::MD5.base64digest(request_body)
          request = Net::HTTP::Post.new(URI::join(@endpoint, "/?delete"))
          request.content_type = 'text/xml'
          request['Content-MD5'] = checksum
          request['Content-Length'] = request_body.length
          request.body = request_body
          sign(request, "?delete", checksum: checksum)
          http.request(request)
        end
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        http_start do |http|
          request = Net::HTTP::Head.new(URI::join(@endpoint, "/#{key}"))
          sign(request, key)
          response = http.request(request)
          answer = response.is_a?(Net::HTTPSuccess)
          payload[:exist] = answer
          answer
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
      sig = signature(
        method: request.method,
        key: key,
        date: date,
        checksum: checksum,
        content_type: request.content_type || ''
      )
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
      request = Net::HTTP::Get.new(URI::join(@endpoint, "/?prefix=#{prefix}"))
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
          keys.each do |k|
            xml.Object do
              xml.Key(k)
            end
          end
        end
      end
      builder.to_xml
    end

    def with_io_length(io)
      if io.respond_to?(:size) && io.respond_to?(:pos)
        yield(io, io.size - io.pos)
      else
        tmp_file = Tempfile.new('cellar_io_lengt')
        begin
          IO.copy_stream(io, tmp_file)
          length = tmp_file.pos
          tmp_file.rewind
          yield(tmp_file, length)
        ensure
          tmp_file.close!
        end
      end
    end
  end
end
