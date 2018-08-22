class SignatureService
  class << self
    def generate
      RbNaCl::Util.bin2hex(RbNaCl::SigningKey.generate)
    end

    def verify(signature, message)
      message = Base64.urlsafe_encode64(message)
      begin
        signing_key.verify_key
          .verify(RbNaCl::Util.hex2bin(signature), message)
      rescue RbNaCl::BadSignatureError, RbNaCl::LengthError
        return false
      end
    end

    def sign(message)
      message = Base64.urlsafe_encode64(message)
      RbNaCl::Util.bin2hex(signing_key.sign(message))
    end

    private

    def signing_key
      @@signing_key ||= RbNaCl::SigningKey.new(RbNaCl::Util.hex2bin(Rails.application.secrets.signing_key))
    end
  end
end
