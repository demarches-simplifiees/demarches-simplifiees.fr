class SignatureService
  class << self
    def verify(signature, message)
      begin
        decoded_message = verifier.verify(signature)
        return message == decoded_message
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        return false
      end
    end

    def sign(message)
      verifier.generate(message)
    end

    private

    def verifier
      @@verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secrets.signing_key)
    end
  end
end
