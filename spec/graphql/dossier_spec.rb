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

  describe 'dossier with champs' do
    let(:procedure) { create(:procedure, :published, :with_commune, :with_address) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }
    let(:query) { DOSSIER_WITH_CHAMPS_QUERY }
    let(:variables) { { number: dossier.id } }

    it { expect(data[:dossier][:champs][0][:__typename]).to eq "CommuneChamp" }
    it { expect(data[:dossier][:champs][1][:__typename]).to eq "AddressChamp" }
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

  DOSSIER_WITH_CHAMPS_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
      champs {
        id
        label
        __typename
        ...CommuneChampFragment
        ... on AddressChamp {
          address {
            ...AddressFragment
          }
        }
      }
    }
  }
  fragment CommuneChampFragment on CommuneChamp {
    commune {
      ...CommuneFragment
    }
  }
  fragment CommuneFragment on Commune {
    code
  }
  fragment AddressFragment on Address {
    cityName
  }
  GRAPHQL
end
