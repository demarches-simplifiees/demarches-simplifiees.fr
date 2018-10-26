require 'base64'
require 'openssl'

module Cellar
  class AmazonV2RequestSigner
    def initialize(access_key_id, secret_access_key, bucket)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @bucket = bucket
    end

    def sign(request, key)
      date = Time.zone.now.httpdate
      sig = signature(
        method: request.method,
        key: key,
        date: date,
        checksum: request['Content-MD5'] || '',
        content_type: request.content_type || ''
      )
      request['date'] = date
      request['authorization'] = "AWS #{@access_key_id}:#{sig}"
    end

    def url_signature_params(method:, key:, expires_in:, content_type: '', checksum: '')
      expires = expires_in.from_now.to_i

      {
        AWSAccessKeyId: @access_key_id,
        Expires: expires,
        Signature: signature(method: method, key: key, expires: expires, content_type: content_type, checksum: checksum)
      }
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
