# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe CopySuperAdminOtpSecretToRails7EncryptedAttrTask do
    describe "#process" do
      let(:super_admin) { create(:super_admin) }
      subject(:process) { described_class.process(super_admin) }

      context "when otp_secret is not set" do
        let(:legacy_otp_secret) { "legacy_secret" }

        before do
          super_admin.update_column(:otp_secret, nil)
          allow(super_admin).to receive(:otp_secret).and_return(legacy_otp_secret)
        end

        it "copies the legacy otp_secret to the new column" do
          expect { process }.to change { super_admin.reload.read_attribute(:otp_secret) }.from(nil).to(legacy_otp_secret)
        end
      end
    end
  end
end
