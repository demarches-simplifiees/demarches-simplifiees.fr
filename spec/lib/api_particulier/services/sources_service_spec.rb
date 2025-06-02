# frozen_string_literal: true

describe APIParticulier::Services::SourcesService do
  let(:service) { described_class.new(procedure) }

  let(:procedure) { create(:procedure) }
  let(:api_particulier_scopes) { [] }
  let(:api_particulier_sources) { {} }

  before do
    procedure.update(api_particulier_scopes: api_particulier_scopes)
    procedure.update(api_particulier_sources: api_particulier_sources)
  end

  describe "#available_sources" do
    subject { service.available_sources }

    context 'when the procedure doesn’t have any available scopes' do
      it { is_expected.to eq({}) }
    end

    context 'when a procedure has a cnaf_allocataires and a cnaf_enfants scopes' do
      let(:api_particulier_scopes) { ['cnaf_allocataires', 'cnaf_enfants'] }

      let(:cnaf_allocataires_and_enfants) do
        {
          'cnaf' => {
            'allocataires' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
            'enfants' => ['nomPrenom', 'dateDeNaissance', 'sexe']
          }
        }
      end

      it { is_expected.to match(cnaf_allocataires_and_enfants) }
    end

    context 'when a procedure has a dgfip_declarant1_nom , prenom and a dgfip_adresse_fiscale_taxation scopes' do
      let(:api_particulier_scopes) { ['dgfip_declarant1_nom', 'dgfip_declarant1_prenoms', 'dgfip_adresse_fiscale_taxation'] }

      let(:dgfip_avis_imposition_et_adresse) do
        {
          'dgfip' => {
            'declarant1' => ['nom', 'prenoms'],
            'foyer_fiscal' => ['adresse']
          }
        }
      end

      it { is_expected.to match(dgfip_avis_imposition_et_adresse) }
    end

    context 'when a procedure has a pole_emploi_identite and a pole_emploi_adresse scopes' do
      let(:api_particulier_scopes) { ['pole_emploi_identite', 'pole_emploi_adresse'] }

      let(:pole_emploi_identite_et_adresse) do
        {
          'pole_emploi' => {
            'identite' => ['identifiant', 'civilite', 'nom', 'nomUsage', 'prenom', 'sexe', 'dateNaissance'],
            'adresse' => ['INSEECommune', 'codePostal', 'localite', 'ligneVoie', 'ligneComplementDestinataire', 'ligneComplementAdresse', 'ligneComplementDistribution', 'ligneNom']
          }
        }
      end

      it { is_expected.to match(pole_emploi_identite_et_adresse) }
    end

    context 'when a procedure has a mesri_identite and a mesri_etablissements scopes' do
      let(:api_particulier_scopes) { ['mesri_identite', 'mesri_etablissements'] }

      let(:mesri_identite_and_etablissements) do
        {
          'mesri' => {
            'identite' => ['nom', 'prenom', 'dateNaissance'],
            'etablissements' => ['uai', 'nom']
          }
        }
      end

      it { is_expected.to match(mesri_identite_and_etablissements) }
    end

    context 'when a procedure has an unknown scope' do
      let(:api_particulier_scopes) { ['unknown_scope'] }

      it { is_expected.to match({}) }
    end
  end

  describe '#sanitize' do
    subject { service.sanitize(requested_sources) }

    let(:api_particulier_scopes) { ['cnaf_allocataires', 'cnaf_adresse'] }
    let(:requested_sources) do
      {
        'cnaf' => {
          'allocataires' => ['nomPrenom', 'forbidden_sources', { 'weird_object' => 1 }],
          'forbidden_scope' => ['any_source'],
          'adresse' => { 'weird_object' => 1 }
        },
        'forbidden_provider' => { 'anything_scope' => ['any_source'] }
      }
    end

    it { is_expected.to eq({ 'cnaf' => { 'allocataires' => ['nomPrenom'] } }) }
  end
end
