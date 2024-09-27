# frozen_string_literal: true

module Maintenance
  RSpec.describe UpdateAPIEntrepriseTokenExpiresAtTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }

      let(:expiration) { 1.month.from_now.beginning_of_minute }
      let(:procedure) { create(:procedure) }

      before do
        procedure.update_column(:api_entreprise_token, JWT.encode({ exp: expiration.to_i }, nil, "none"))
      end

      it do
        expect { process }.to change { procedure.reload.api_entreprise_token_expires_at }.from(nil).to(expiration)
      end
    end
  end
end
