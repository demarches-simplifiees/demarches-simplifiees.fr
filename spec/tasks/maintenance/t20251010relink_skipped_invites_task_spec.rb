# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251010relinkSkippedInvitesTask do
    describe "#process" do
      let(:dossier) { create(:dossier) }
      let(:invite_email) { "test@example.com" }
      let(:invite) { create(:invite, dossier: dossier, email: invite_email, user: nil) }
      let(:user) { create(:user, email: invite_email) }

      subject(:process) { described_class.process([invite]) }

      context "when there is a user with matching email" do
        before { user }
        it "links the invite to the user" do
          expect { process }.to change { invite.reload.user }.from(nil).to(user)
        end
      end
    end
  end
end
