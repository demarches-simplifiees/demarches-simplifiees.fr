RSpec.describe Types::DossierType, type: :graphql do
  let(:query) { DOSSIER_QUERY }
  let(:context) { { internal_use: true } }
  let(:variables) { {} }

  subject { API::V2::Schema.execute(query, variables: variables, context: context) }

  let(:data) { subject['data'].deep_symbolize_keys }
  let(:errors) { subject['errors'].deep_symbolize_keys }

  describe 'dossier with attestation' do
    let(:dossier) { create(:dossier, :accepte, :with_attestation) }
    let(:query) { DOSSIER_WITH_ATTESTATION_QUERY }
    let(:variables) { { number: dossier.id } }

    it { expect(data[:dossier][:attestation]).not_to be_nil }
    it { expect(data[:dossier][:traitements]).to eq([{ state: 'accepte' }]) }
    it { expect(data[:dossier][:dateExpiration]).not_to be_nil }

    context 'when attestation is nil' do
      before do
        dossier.update(attestation: nil)
      end

      it { expect(data[:dossier][:attestation]).to be_nil }
    end
  end

  DOSSIER_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
    }
  }
  GRAPHQL

  DOSSIER_WITH_ATTESTATION_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      attestation {
        url
      }
      traitements {
        state
      }
      dateExpiration
    }
  }
  GRAPHQL
end
