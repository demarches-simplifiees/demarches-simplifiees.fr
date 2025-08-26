# frozen_string_literal: true

describe APIEntrepriseTokenConcern do
  describe '#set_api_entreprise_token_expires_at (before_save)' do
    let(:procedure) { create(:procedure, api_entreprise_token: initial_api_entreprise_token) }

    before do
      procedure.api_entreprise_token = api_entreprise_token
    end

    subject { procedure.save }

    context "when procedure had no api_entreprise_token" do
      let(:initial_api_entreprise_token) { nil }

      context 'when the api_entreprise_token is nil' do
        let(:api_entreprise_token) { nil }

        it 'does not set the api_entreprise_token_expires_at' do
          expect { subject }.not_to change { procedure.api_entreprise_token_expires_at }.from(nil)
        end
      end

      context 'when the api_entreprise_token is not valid' do
        let(:api_entreprise_token) { "not a token" }

        it do
          expect { subject }.not_to change { procedure.api_entreprise_token_expires_at }.from(nil)
        end
      end

      context 'when the api_entreprise_token is valid' do
        let(:expiration_date) { Time.zone.now.beginning_of_minute }
        let(:api_entreprise_token) { JWT.encode({ exp: expiration_date.to_i }, nil, 'none') }

        it do
          expect { subject }.to change { procedure.api_entreprise_token_expires_at }.from(nil).to(expiration_date)
        end
      end
    end

    context "when procedure had an api_entreprise_token" do
      let(:initial_api_entreprise_token) { JWT.encode({ exp: 2.months.from_now.to_i }, nil, "none") }

      context 'when the api_entreprise_token is set to nil' do
        let(:api_entreprise_token) { nil }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('API_ENTREPRISE_KEY').and_return(nil)
        end

        it do
          expect { subject }.to change { procedure.api_entreprise_token_expires_at }.to(nil)
        end
      end
    end
  end
end
