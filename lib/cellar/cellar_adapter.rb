require 'net/http'
require 'openssl'

module Cellar
  class CellarAdapter
    def initialize(access_key_id, secret_access_key, bucket)
      @endpoint = URI::HTTPS.build(host: "#{bucket}.cellar.services.clever-cloud.com")
      @signer = AmazonV2RequestSigner.new(access_key_id, secret_access_key, bucket)
    end

    def presigned_url(method:, key:, expires_in:, content_type: '', checksum: '', **query_params)
      query = query_params.merge(
        @signer.url_signature_params(
          method: method,
          key: key,
          expires_in: expires_in,
          content_type: content_type,
          checksum: checksum
        )
      )

      URI::join(@endpoint, "/#{key}", "?#{query.to_query}").to_s
    end

    def session
      Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: true) do |http|
        yield Session.new(http, @signer)
      end
    end

    class Session
      def initialize(http, signer)
        @http = http
        @signer = signer
      end

      def upload(key, io, checksum)
        with_io_length(io) do |io, length|
          request = Net::HTTP::Put.new("/#{key}")
          request.content_type = 'application/octet-stream'
          request['Content-MD5'] = checksum
          request['Content-Length'] = length
          request.body_stream = io
          @signer.sign(request, key)
          @http.request(request)
          # TODO: error handling
        end
      end

      def download(key, range: nil)
        request = Net::HTTP::Get.new("/#{key}")
        if range.present?
          add_range_header(request, range)
        end
        @signer.sign(request, key)
        if block_given?
          @http.request(request) do |response|
            if response.is_a?(Net::HTTPSuccess)
              response.read_body do |chunk|
                yield(chunk.force_encoding(Encoding::BINARY))
              end
            else
              # TODO: error handling
            end
          end
        else
          response = @http.request(request)
          if response.is_a?(Net::HTTPSuccess)
            response.body.force_encoding(Encoding::BINARY)
          else
            # TODO: error handling
          end
        end
      end

      def delete(key)
        # TODO: error handling
        request = Net::HTTP::Delete.new("/#{key}")
        @signer.sign(request, key)
        @http.request(request)
      end

      def list_prefixed(prefix)
        request = Net::HTTP::Get.new("/?prefix=#{prefix}")
        @signer.sign(request, "")
        response = @http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          parse_bucket_listing(response.body)
        end
      end

      def delete_keys(keys)
        request_body = bulk_deletion_request_body(keys)
        request = Net::HTTP::Post.new("/?delete")
        request.content_type = 'text/xml'
        request['Content-MD5'] = Digest::MD5.base64digest(request_body)
        request['Content-Length'] = request_body.length
        request.body = request_body
        @signer.sign(request, "?delete")
        @http.request(request)
      end

      def exist?(key)
        request = Net::HTTP::Head.new("/#{key}")
        @signer.sign(request, key)
        response = @http.request(request)
        response.is_a?(Net::HTTPSuccess)
      end

      def last_modified(key)
        request = Net::HTTP::Head.new("/#{key}")
        @signer.sign(request, key)
        response = @http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          Time.zone.parse(response['Last-Modified'])
        end
      end

      private

      def add_range_header(request, range)
        bytes_end = range.exclude_end? ? range.end - 1 : range.end

        request['range'] = "bytes=#{range.begin}-#{bytes_end}"
      end

      def parse_bucket_listing(bucket_listing_xml)
        doc = Nokogiri::XML(bucket_listing_xml)
        doc
          .xpath('//xmlns:Contents/xmlns:Key')
          .map(&:text)
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
          tmp_file = Tempfile.new('cellar_io_length')
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
end
