# frozen_string_literal: true

class EncryptionService
  def initialize
    len        = ActiveSupport::MessageEncryptor.key_len
    salt       = Rails.application.secrets.encryption_service_salt
    password   = Rails.application.secrets.secret_key_base
    key        = ActiveSupport::KeyGenerator.new(password).generate_key(salt, len)
    @encryptor = ActiveSupport::MessageEncryptor.new(key)

    # Remove after all encrypted attributes have been rotated.
    legacy_key = ActiveSupport::KeyGenerator.new(password, hash_digest_class: OpenSSL::Digest::SHA1).generate_key(salt, len)
    @encryptor.rotate legacy_key
  end

  def encrypt(value)
    value.blank? ? nil : @encryptor.encrypt_and_sign(value)
  end

  def decrypt(value)
    value.blank? ? nil : @encryptor.decrypt_and_verify(value)
  end
end
