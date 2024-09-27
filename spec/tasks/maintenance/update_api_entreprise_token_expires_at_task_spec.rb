# frozen_string_literal: true

module Maintenance
  RSpec.describe UpdateAPIEntrepriseTokenExpiresAtTask do
    describe '#collection' do
      subject(:collection) { described_class.collection }

      let!(:procedures_with_token) { create_list(:procedure, 3, api_entreprise_token: JWT.encode({}, nil, 'none')) }
      let!(:procedure_without_token) { create(:procedure, api_entreprise_token: nil) }

      it 'returns procedures with api_entreprise_token present' do
        expect(collection).to match_array(procedures_with_token)

        expect(collection).not_to include(procedure_without_token)
      end
    end

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
