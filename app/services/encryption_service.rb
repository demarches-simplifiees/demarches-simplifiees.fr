class EncryptionService
  class Error < ::StandardError; end

  def initialize(**kwargs)
    attrs = kwargs.symbolize_keys
    @encryption_service_salt = attrs[:encryption_service_salt]
    @secret_key_base = attrs[:secret_key_base]
    @key_len = attrs[:key_len]
    @key_generator = attrs[:key_generator]
    @encryptor_class = attrs[:encryptor_class]
  end

  delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

  def encrypt(value)
    value.blank? ? nil : encrypt_and_sign(value)
  end

  def decrypt(value)
    value.blank? ? nil : decrypt_and_verify(value)
  rescue StandardError => e
    raise EncryptionService::Error, e.message
  end

  private

  def secret_key_base
    @secret_key_base || Rails.application.secrets.secret_key_base
  end

  def secret_key_base!
    secret_key_base.presence.tap do |secret|
      raise EncryptionService::Error, "missing secret key base" if secret.nil?
    end
  end

  def key_generator
    @key_generator || ActiveSupport::KeyGenerator.new(secret_key_base!)
  end

  def encryption_service_salt
    @encryption_service_salt || Rails.application.secrets.encryption_service_salt
  end

  def encryption_service_salt!
    encryption_service_salt.presence.tap do |salt|
      raise EncryptionService::Error, "missing encryption service salt" if salt.nil?
    end
  end

  def encryptor_class
    @encryptor_class || ActiveSupport::MessageEncryptor
  end

  def key_len
    @key_len || encryptor_class.key_len
  end

  def key
    @key ||= key_generator.generate_key(encryption_service_salt!, key_len).freeze
  end

  def encryptor
    @encryptor ||= encryptor_class.new(key)
  end
end
