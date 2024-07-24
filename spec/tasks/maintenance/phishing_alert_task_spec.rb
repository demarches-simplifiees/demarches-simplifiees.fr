# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe PhishingAlertTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let(:element) { { 'Identity' => '"' + email + '"' } }

      describe "when the user does not exist" do
        let(:email) { "not@existing.com" }

        it { expect { process }.not_to raise_error }
      end

      describe "when the user exist" do
        let(:user) { create(:user, updated_at: 1.day.ago) }
        let(:email) { user.email }

        before { allow(PhishingAlertMailer).to receive(:notify).and_return(double(deliver_later: true)) }

        it "resets its password and send a mail" do
          previous_password = user.encrypted_password

          process

          expect(user.reload.encrypted_password).not_to eq(previous_password)
          expect(PhishingAlertMailer).to have_received(:notify).with(user)
        end
      end

      describe "when the emails is present several times" do
        let(:user) { create(:user, updated_at: 1.day.ago) }
        let(:email) { user.email }

        before { allow(PhishingAlertMailer).to receive(:notify).and_return(double(deliver_later: true)) }

        it "resets its password and send a mail" do
          described_class.process(element)
          described_class.process(element)

          expect(PhishingAlertMailer).to have_received(:notify).with(user).once
        end
      end
    end
  end
end
