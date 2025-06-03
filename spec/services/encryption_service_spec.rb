# frozen_string_literal: true

describe EncryptionService do
  describe "#encrypt" do
    subject { EncryptionService.new.encrypt(value) }

    context "with a nil value" do
      let(:value) { nil }

      it { expect(subject).to be_nil }
    end

    context "with a string value" do
      let(:value) { "The quick brown fox jumps over the lazy dog" }

      it { expect(subject).to be_instance_of(String) }
      it { expect(subject).to be_present }
      it { expect(subject).not_to eq(value) }
    end
  end

  describe "#decrypt" do
    subject { EncryptionService.new.decrypt(encrypted_value) }

    context "with a nil value" do
      let(:encrypted_value) { nil }

      it { expect(subject).to be_nil }
    end

    context "with a string value" do
      let (:value) { "The quick brown fox jumps over the lazy dog" }
      let(:encrypted_value) { EncryptionService.new.encrypt(value) }

      it { expect(subject).to eq(value) }
    end

    context "with an invalid value" do
      let(:encrypted_value) { "Gur dhvpx oebja sbk whzcf bire gur ynml qbt" }

      it { expect { subject }.to raise_exception StandardError }
    end
  end

  describe "key rotation" do
    let(:password) { Rails.application.secrets.secret_key_base }
    let(:salt) { Rails.application.secrets.encryption_service_salt }
    let(:len) { ActiveSupport::MessageEncryptor.key_len }
    let(:value) { "Sensitive information" }

    let(:legacy_key) do
      ActiveSupport::KeyGenerator.new(password, hash_digest_class: OpenSSL::Digest::SHA1)
        .generate_key(salt, len)
    end

    let(:new_key) do
      ActiveSupport::KeyGenerator.new(password)
        .generate_key(salt, len)
    end

    let(:legacy_encryptor) { ActiveSupport::MessageEncryptor.new(legacy_key) }
    let(:new_encryptor) { ActiveSupport::MessageEncryptor.new(new_key) }

    describe "#decrypt" do
      subject { EncryptionService.new.decrypt(encrypted_value) }

      context "with a value encrypted using the legacy SHA1-based key" do
        let(:encrypted_value) { legacy_encryptor.encrypt_and_sign(value) }

        it "successfully decrypts the value" do
          expect(subject).to eq(value)
        end
      end

      context "with a value encrypted using the new SHA256-based key" do
        let(:encrypted_value) { new_encryptor.encrypt_and_sign(value) }

        it "successfully decrypts the value" do
          expect(subject).to eq(value)
        end
      end
    end

    describe "transition from legacy to new encryption" do
      let(:legacy_service) do
        legacy_encryption_service = EncryptionService.new
        legacy_encryption_service.instance_variable_set(:@encryptor, legacy_encryptor)
        legacy_encryption_service
      end

      let(:new_service) { EncryptionService.new }

      it "can decrypt values encrypted with the legacy key" do
        legacy_encrypted = legacy_service.encrypt(value)
        expect(new_service.decrypt(legacy_encrypted)).to eq(value)
      end

      it "uses the new key for new encryptions" do
        new_encrypted = new_service.encrypt(value)
        expect { legacy_encryptor.decrypt_and_verify(new_encrypted) }
          .to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
        expect(new_encryptor.decrypt_and_verify(new_encrypted)).to eq(value)
      end
    end

    describe "backwards compatibility" do
      let(:value) { "Important data" }
      let(:old_service) do # Test with a service encrypting data without rotation mechanism
        Class.new do
          def initialize(key)
            @encryptor = ActiveSupport::MessageEncryptor.new(key)
          end

          def encrypt(value)
            @encryptor.encrypt_and_sign(value)
          end
        end
      end

      it "can decrypt values from a hypothetical old version without rotation" do
        old_key = ActiveSupport::KeyGenerator.new(password, hash_digest_class: OpenSSL::Digest::SHA1)
          .generate_key(salt, len)
        old_encrypted = old_service.new(old_key).encrypt(value)

        expect(EncryptionService.new.decrypt(old_encrypted)).to eq(value)
      end
    end
  end
end
