# frozen_string_literal: true

module Maintenance
  RSpec.describe VerifyConfirmedUsersTask do
    describe "#process" do
      subject(:process) { described_class.process }

      let!(:unverified_confirmed_user) { create(:user, confirmed_at: Time.zone.now) }
      let!(:unverified_unconfirmed_user) { create(:user, confirmed_at: nil) }
      let!(:unverified_confirmed_instructeur) do
        user = create(:instructeur).user
        user.update!(confirmed_at: Time.zone.now)
        user
      end

      let!(:unverified_confirmed_expert) do
        user = create(:expert).user
        user.update!(confirmed_at: Time.zone.now)
        user
      end

      it 'verifies only confirmed user' do
        process

        expect(unverified_confirmed_user.reload.email_verified_at).to be_present

        expect(unverified_unconfirmed_user.reload.email_verified_at).to be_nil
        expect(unverified_confirmed_instructeur.reload.email_verified_at).to be_nil
        expect(unverified_confirmed_expert.reload.email_verified_at).to be_nil
      end
    end
  end
end
