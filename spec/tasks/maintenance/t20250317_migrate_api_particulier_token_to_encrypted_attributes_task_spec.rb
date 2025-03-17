# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250317MigrateAPIParticulierTokenToEncryptedAttributesTask do
    describe "#process" do
      subject(:task) { described_class.new }

      context "when procedure has encrypted_api_particulier_token" do
        let(:api_token) { "abc123-test-token-456xyz" }
        let(:procedure) { create(:procedure) }

        before do
          encrypted_value = EncryptionService.new.encrypt(api_token)
          procedure.update_column(:encrypted_api_particulier_token, encrypted_value)

          procedure.reload
        end

        it "migrates the token to the new encrypted attribute" do
          expect(procedure.encrypted_api_particulier_token).to be_present

          expect(EncryptionService.new.decrypt(procedure.encrypted_api_particulier_token)).to eq(api_token)

          task.process(procedure)
          procedure.reload

          expect(procedure.api_particulier_token).to eq(api_token)
          expect(procedure.encrypted_api_particulier_token).to be_nil
        end
      end
    end
  end
end
