# frozen_string_literal: true

describe APIEntrepriseTokenConcern do
  context 'api_entreprise_token validity' do
    let(:valid_token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }
    let(:invalid_token) { 'plouf' }
    let(:procedure) { build(:procedure, api_entreprise_token:) }

    context 'with a valid token' do
      let(:api_entreprise_token) { valid_token }

      it { expect(procedure.valid?).to eq(true) }
    end

    context 'with an invalid token' do
      let(:api_entreprise_token) { invalid_token }

      it { expect(procedure.valid?).to eq(false) }
    end

    context 'with a nil token' do
      let(:api_entreprise_token) { nil }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('API_ENTREPRISE_KEY').and_return(nil)
      end

      it { expect(procedure.valid?).to eq(true) }
    end
  end
end
