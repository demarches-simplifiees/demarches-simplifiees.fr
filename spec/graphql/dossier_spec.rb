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
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :communes }, { type: :address }]) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }
    let(:query) { DOSSIER_WITH_CHAMPS_QUERY }
    let(:variables) { { number: dossier.id } }
    let(:address) do
      {
        "type" => "housenumber",
        "label" => "33 Rue Rébeval 75019 Paris",
        "city_code" => "75119",
        "city_name" => "Paris",
        "postal_code" => "75019",
        "region_code" => "11",
        "region_name" => "Île-de-France",
        "street_name" => "Rue Rébeval",
        "street_number" => "33",
        "street_address" => "33 Rue Rébeval",
        "department_code" => "75",
        "department_name" => "Paris"
      }
    end

    before do
      dossier.champs_public.second.update(data: address)
    end

    it { expect(data[:dossier][:champs][0][:__typename]).to eq "CommuneChamp" }
    it { expect(data[:dossier][:champs][1][:__typename]).to eq "AddressChamp" }
    it { expect(data[:dossier][:champs][0][:id]).to eq(data[:dossier][:revision][:champDescriptors][0][:id]) }
  end

  describe 'dossier with conditional champs' do
    include Logic
    let(:stable_id) { 1234 }
    let(:condition) { ds_eq(champ_value(stable_id), constant(true)) }
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :checkbox, stable_id: stable_id }, { type: :text, condition: condition }]) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }
    let(:query) { DOSSIER_WITH_CHAMPS_QUERY }
    let(:variables) { { number: dossier.id } }
    let(:checkbox_value) { 'on' }

    before do
      dossier.champs_public.first.update(value: checkbox_value)
    end

    context 'when checkbox is true' do
      it { expect(data[:dossier][:champs].size).to eq 2 }
      it { expect(data[:dossier][:champs][0][:__typename]).to eq "CheckboxChamp" }
      it { expect(data[:dossier][:champs][1][:__typename]).to eq "TextChamp" }
    end

    context 'when checkbox is false' do
      let(:checkbox_value) { 'off' }
      it { expect(data[:dossier][:champs].size).to eq 1 }
      it { expect(data[:dossier][:champs][0][:__typename]).to eq "CheckboxChamp" }
    end
  end

  describe 'dossier with user' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:query) { DOSSIER_WITH_USAGER_QUERY }
    let(:variables) { { number: dossier.id } }

    it { expect(data[:dossier][:usager]).not_to be_nil }
  end

  describe 'dossier with deleted user' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:query) { DOSSIER_WITH_USAGER_QUERY }
    let(:variables) { { number: dossier.id } }
    let(:email) { dossier.user.email }

    before do
      dossier.update(user_id: nil, deleted_user_email_never_send: email)
    end

    it {
      expect(data[:dossier][:usager]).not_to be_nil
      expect(data[:dossier][:usager][:email]).to eq(email)
      expect(data[:dossier][:usager][:id]).to eq('<deleted>')
    }
  end

  describe 'dossier with linked dossier' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :dossier_link }]) }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }
    let(:linked_dossier) { create(:dossier, :en_construction) }
    let(:query) { DOSSIER_WITH_LINKED_DOSIER_QUERY }
    let(:variables) { { number: dossier.id } }

    before do
      dossier.champs_public.first.update(value: linked_dossier.id)
    end

    context 'en_construction' do
      it {
        expect(data[:dossier][:champs].first).not_to be_nil
        expect(data[:dossier][:champs].first[:dossier][:id]).to eq(linked_dossier.to_typed_id)
        expect(data[:dossier][:champs].first[:dossier][:state]).to eq('en_construction')
      }
    end

    context 'brouillon' do
      let(:linked_dossier) { create(:dossier, :brouillon) }

      it {
        expect(data[:dossier][:champs].first).not_to be_nil
        expect(data[:dossier][:champs].first[:dossier]).to be_nil
      }
    end
  end

  describe 'dossier with repetition' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :repetition, children: [{ libelle: 'Nom' }, { libelle: 'Age' }] }]) }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }
    let(:linked_dossier) { create(:dossier, :en_construction) }
    let(:query) { DOSSIER_WITH_REPETITION_QUERY }
    let(:variables) { { number: dossier.id } }

    let(:rows) do
      dossier.champs_public.first.rows.map do |champs|
        { champs: champs.map { { id: _1.to_typed_id } } }
      end
    end

    it {
      expect(data[:dossier][:champs].first).not_to be_nil
      expect(data[:dossier][:champs].first[:rows]).not_to be_nil
      expect(data[:dossier][:champs].first[:rows].size).to eq(2)
      expect(data[:dossier][:champs].first[:rows]).to eq(rows)
    }
  end

  describe 'dossier with titre identite filled' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :titre_identite }]) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }

    let(:query) { DOSSIER_WITH_TITRE_IDENTITE_QUERY }
    let(:variables) { { number: dossier.id } }

    it {
      expect(data[:dossier][:champs][0][:filled]).to eq(true)
    }
  end

  describe 'dossier with titre identite not filled' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :titre_identite }]) }
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

    let(:query) { DOSSIER_WITH_TITRE_IDENTITE_QUERY }
    let(:variables) { { number: dossier.id } }

    it {
      expect(data[:dossier][:champs][0][:filled]).to eq(false)
    }
  end

  describe 'dossier with motivation attachment' do
    let(:dossier) { create(:dossier, :accepte, :with_motivation, :with_justificatif) }
    let(:query) { DOSSIER_WITH_MOTIVATION_QUERY }
    let(:variables) { { number: dossier.id } }

    it {
      expect(data[:dossier][:motivationAttachment][:url]).not_to be_nil
    }
  end

  DOSSIER_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
    }
  }
  GRAPHQL

  DOSSIER_WITH_USAGER_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
      usager {
        id
        email
      }
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

  DOSSIER_WITH_MOTIVATION_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      motivationAttachment {
        url
      }
    }
  }
  GRAPHQL

  DOSSIER_WITH_CHAMPS_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
      revision {
        champDescriptors {
          id
          label
        }
      }
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
    type
    label
    cityName
    cityCode
    streetName
    streetNumber
  }
  GRAPHQL

  DOSSIER_WITH_LINKED_DOSIER_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      champs {
        id
        ... on DossierLinkChamp {
          dossier {
            id
            state
          }
        }
      }
    }
  }
  GRAPHQL

  DOSSIER_WITH_REPETITION_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      champs {
        id
        ... on RepetitionChamp {
          rows {
            champs { id }
          }
        }
      }
    }
  }
  GRAPHQL

  DOSSIER_WITH_TITRE_IDENTITE_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      id
      number
      champs {
        id
        label
        __typename
        ... on TitreIdentiteChamp {
          filled
        }
      }
    }
  }
  GRAPHQL
end
