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
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :communes }, { type: :address }, { type: :siret }, { type: :rna }]) }
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

    let(:rna) do
      {
        "adresse" => {
          "commune" => "Paris 14e",
          "type_voie" => "RUE",
          "code_insee" => "75114",
          "complement" => nil,
          "code_postal" => "75512",
          "numero_voie" => "12",
          "distribution" => nil,
          "libelle_voie" => "xyz"
        },
       "association_rna" => "W173847273",
       "association_objet" => "prévenir",
       "association_titre" => "CROIX ROUGE",
       "association_date_creation" => "1964-12-30",
       "association_date_declaration" => "2022-08-10"
      }
    end

    before do
      dossier.champs_public.find { _1.type_champ == TypeDeChamp.type_champs.fetch(:address) }.update(data: address)
      dossier.champs_public.find { _1.type_champ == TypeDeChamp.type_champs.fetch(:rna) }.update(data: rna)
    end

    it do
      expect(data[:dossier][:champs][0][:__typename]).to eq "CommuneChamp"
      expect(data[:dossier][:champs][1][:__typename]).to eq "AddressChamp"
      expect(data[:dossier][:champs][2][:__typename]).to eq "SiretChamp"
      expect(data[:dossier][:champs][1][:commune][:code]).to eq('75119')
      expect(data[:dossier][:champs][1][:commune][:postalCode]).to eq('75019')
      expect(data[:dossier][:champs][1][:departement][:code]).to eq('75')
      expect(data[:dossier][:champs][2][:etablissement][:siret]).to eq dossier.champs_public[2].etablissement.siret
      expect(data[:dossier][:champs][0][:id]).to eq(data[:dossier][:revision][:champDescriptors][0][:id])

      expect(data[:dossier][:champs][1][:address][:cityName]).to eq('Paris 19e Arrondissement')
      expect(data[:dossier][:champs][1][:address][:departmentName]).to eq('Paris')
      expect(data[:dossier][:champs][1][:address][:regionName]).to eq('Île-de-France')

      expect(data[:dossier][:champs][3][:rna][:id]).to eq('W173847273')
      expect(data[:dossier][:champs][3][:rna][:title]).to eq('CROIX ROUGE')
      expect(data[:dossier][:champs][3][:rna][:address][:label]).to eq('12 RUE xyz 75512 Paris 14e')
      expect(data[:dossier][:champs][3][:rna][:address][:streetNumber]).to eq('12')
      expect(data[:dossier][:champs][3][:rna][:address][:cityName]).to eq('Paris 14e')
      expect(data[:dossier][:champs][3][:rna][:address][:departmentName]).to eq(nil)
      expect(data[:dossier][:champs][3][:rna][:address][:regionName]).to eq(nil)
    end

    context 'when etablissement is in degraded mode' do
      let(:etablissement) { dossier.champs_public.third.etablissement }
      before do
        etablissement.update(adresse: nil)
      end

      it do
        expect(etablissement).to be_as_degraded_mode
        expect(data[:dossier][:champs][2][:__typename]).to eq "SiretChamp"
        expect(data[:dossier][:champs][2][:etablissement]).to be_nil
      end
    end
  end

  describe 'dossier with annotations' do
    let(:procedure) { create(:procedure, :published, types_de_champ_private: [{ type: :engagement_juridique }]) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }
    let(:query) { DOSSIER_WITH_ANNOTATIONS_QUERY }
    let(:variables) { { number: dossier.id } }

    it do
      expect(data[:dossier][:annotations][0][:__typename]).to eq "EngagementJuridiqueChamp"
    end
  end

  describe 'dossier with selected champ' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ libelle: 'yolo' }, { libelle: 'toto' }]) }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }
    let(:query) { DOSSIER_WITH_SELECTED_CHAMP_QUERY }
    let(:variables) { { number: dossier.id, id: champ.to_typed_id } }
    let(:champ) { dossier.champs_public.last }

    context 'when champ exists' do
      it {
        expect(data[:dossier][:champs].size).to eq 1
        expect(data[:dossier][:champs][0][:label]).to eq "toto"
      }
    end

    context "when champ dosen't exists" do
      let(:variables) { { number: dossier.id, id: '1234' } }

      it { expect(data[:dossier][:champs].size).to eq 0 }
    end
  end

  describe 'dossier with conditional champs' do
    include Logic
    let(:stable_id) { 1234 }
    let(:condition) { ds_eq(champ_value(stable_id), constant(true)) }
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :checkbox, stable_id: stable_id }, { type: :text, condition: condition }]) }
    let(:dossier) { create(:dossier, :accepte, :with_populated_champs, procedure: procedure) }
    let(:query) { DOSSIER_WITH_CHAMPS_QUERY }
    let(:variables) { { number: dossier.id } }
    let(:checkbox_value) { 'true' }

    before do
      dossier.champs_public.first.update(value: checkbox_value)
    end

    context 'when checkbox is true' do
      it { expect(data[:dossier][:champs].size).to eq 2 }
      it { expect(data[:dossier][:champs][0][:__typename]).to eq "CheckboxChamp" }
      it { expect(data[:dossier][:champs][1][:__typename]).to eq "TextChamp" }
    end

    context 'when checkbox is false' do
      let(:checkbox_value) { 'false' }
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

  describe 'dossier with message with no attachments' do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:query) { DOSSIER_WITH_MESSAGE_QUERY }
    let(:variables) { { number: dossier.id } }

    before { create(:commentaire, dossier: dossier) }

    it {
      expect(data[:dossier][:messages]).not_to be_nil
      expect(data[:dossier][:messages][0][:correction]).to be_nil
    }
  end

  describe 'dossier with pending correction' do
    let(:dossier) { create(:dossier, :en_construction) }
    let!(:correction) { create(:dossier_correction, dossier:) }
    let(:query) { DOSSIER_WITH_CORRECTION_QUERY }
    let(:variables) { { number: dossier.id } }

    it {
      expect(data[:dossier][:messages][0][:correction]).to eq({ reason: "incorrect", dateResolution: nil })
      expect(data[:dossier][:dateDerniereCorrectionEnAttente]).not_to be_nil
    }
  end

  describe 'dossier on sva procedure' do
    let(:procedure) { create(:procedure, :sva) }
    let(:query) { DOSSIER_WITH_SVA_QUERY }
    let(:variables) { { number: dossier.id } }

    context 'dossier en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction, procedure:, sva_svr_decision_on: 3.days.from_now.to_date) }

      it {
        expect(data[:dossier][:datePrevisionnelleDecisionSVASVR]).not_to be_nil
      }
    end

    context 'dossier accepte' do
      let(:dossier) { create(:dossier, :accepte, procedure:, sva_svr_decision_triggered_at: 24.hours.ago) }

      it {
        expect(data[:dossier][:dateTraitementSVASVR]).not_to be_nil
      }
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
  DOSSIER_WITH_ANNOTATIONS_QUERY = <<-GRAPHQL
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
      annotations {
        id
        label
        __typename
        ... on EngagementJuridiqueChamp {
          engagementJuridique {
            ...EngagementJuridiqueFragment
          }
        }
      }
    }
  }
  fragment EngagementJuridiqueFragment on EngagementJuridique {
    montantEngage
    montantPaye
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
          commune {
            ...CommuneFragment
          }
          departement {
            name
            code
          }
        }
        ... on SiretChamp {
          etablissement {
            siret
            entreprise { capitalSocial }
          }
        }

        ...RNAChampFragment
      }
    }
  }
  fragment CommuneChampFragment on CommuneChamp {
    commune {
      ...CommuneFragment
    }
    departement {
      name
      code
    }
  }
  fragment CommuneFragment on Commune {
    name
    code
    postalCode
  }
  fragment AddressFragment on Address {
    type
    label
    cityName
    cityCode
    streetName
    streetNumber
    departmentName
    regionName
  }

  fragment RNAChampFragment on RNAChamp {
    stringValue
    rna {
      id
      title
      address {
        ...AddressFragment
      }
    }
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

  DOSSIER_WITH_MESSAGE_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      messages {
        body
        attachments {
          filename
        }
      }
    }
  }
  GRAPHQL

  DOSSIER_WITH_CORRECTION_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      dateDerniereCorrectionEnAttente
      messages {
        body
        correction {
          reason
          dateResolution
        }
      }
    }
  }
  GRAPHQL

  DOSSIER_WITH_SVA_QUERY = <<-GRAPHQL
  query($number: Int!) {
    dossier(number: $number) {
      datePrevisionnelleDecisionSVASVR
      dateTraitementSVASVR
    }
  }
  GRAPHQL

  DOSSIER_WITH_SELECTED_CHAMP_QUERY = <<-GRAPHQL
  query($number: Int!, $id: ID!) {
    dossier(number: $number) {
      champs(id: $id) {
        id
        label
      }
    }
  }
  GRAPHQL
end
