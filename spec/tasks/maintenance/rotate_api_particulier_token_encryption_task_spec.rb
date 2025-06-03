# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe RotateAPIParticulierTokenEncryptionTask do
    describe "#process" do
      subject { described_class.process(procedure) }
      let(:token) { "secret-token-0123456789" }
      let(:procedure) { create(:procedure) }
      let(:legacy_encryption_service) do
        EncryptionService.new.tap { |legacy_service|
          legacy_key = ActiveSupport::KeyGenerator
            .new(Rails.application.secrets.secret_key_base, hash_digest_class: OpenSSL::Digest::SHA1)
            .generate_key(Rails.application.secrets.encryption_service_salt, ActiveSupport::MessageEncryptor.key_len)
          legacy_encryptor = ActiveSupport::MessageEncryptor.new(legacy_key)
          legacy_service.instance_variable_set(:@encryptor, legacy_encryptor)
        }
      end

      before do
        # Encrypt the token using the legacy (SHA1) encryption service
        legacy_encrypted_token = legacy_encryption_service.encrypt(token)
        procedure.update_column(:encrypted_api_particulier_token, legacy_encrypted_token)
      end

      it 're-encrypts the api_particulier_token' do
        old_encrypted_value = procedure.encrypted_api_particulier_token

        expect { subject }.to change { procedure.reload.encrypted_api_particulier_token }
        expect(procedure.api_particulier_token).to eq(token)

        encrypted_value = procedure.encrypted_api_particulier_token

        # Verify that the new encrypted value can't be decrypted with the legacy service
        expect { legacy_encryption_service.decrypt(encrypted_value) }
          .to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)

        # Verify that the new encrypted value can be decrypted with the current service
        current_service = EncryptionService.new
        expect(current_service.decrypt(encrypted_value)).to eq(token)

        # and with the services without rotations
        current_service = EncryptionService.new
        current_service.instance_variable_set(:@rotations, [])
        expect(current_service.decrypt(encrypted_value)).to eq(token)
      end
    end
  end
end
