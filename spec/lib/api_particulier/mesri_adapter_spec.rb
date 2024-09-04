# frozen_string_literal: true

describe APIParticulier::MesriAdapter do
  let(:adapter) { described_class.new(api_particulier_token, ine, requested_sources) }

  before { stub_const('API_PARTICULIER_URL', 'https://particulier.api.gouv.fr/api') }

  describe '#to_params' do
    let(:api_particulier_token) { 'c6d23f3900b8fb4b3586c4804c051af79062f54b' }
    let(:ine) { '090601811AB' }

    subject { VCR.use_cassette(cassette) { adapter.to_params } }

    context 'when the api answer is valid' do
      let(:cassette) { 'api_particulier/success/etudiants' }

      context 'when the token has all the MESRI scopes' do
        context 'and all the sources are requested' do
          let(:requested_sources) do
            {
              'mesri' => {
                'identifiant' => ['ine'],
                'identite' => ['nom', 'prenom', 'dateNaissance'],
                'inscriptions' => ['statut', 'regime', 'dateDebutInscription', 'dateFinInscription', 'codeCommune'],
                'admissions' => ['statut', 'regime', 'dateDebutAdmission', 'dateFinAdmission', 'codeCommune'],
                'etablissements' => ['uai', 'nom']
              }
            }
          end

          let(:result) { JSON.parse(File.read('spec/fixtures/files/api_particulier/etudiants.json')) }

          it { is_expected.to eq(result) }
        end

        context 'when no sources is requested' do
          let(:requested_sources) { {} }

          it { is_expected.to eq({}) }
        end

        context 'when an admission statut is requested' do
          let(:requested_sources) { { 'mesri' => { 'admissions' => ['statut'] } } }

          it { is_expected.to eq('admissions' => [{ 'statut' => 'admis' }]) }
        end

        context 'when an inscription statut is requested' do
          let(:requested_sources) { { 'mesri' => { 'inscriptions' => ['statut'] } } }

          it { is_expected.to eq('inscriptions' => [{ 'statut' => 'inscrit' }]) }
        end

        context 'when a first name is requested' do
          let(:requested_sources) { { 'mesri' => { 'identite' => ['prenom'] } } }

          it { is_expected.to eq('identite' => { 'prenom' => 'Angela Claire Louise' }) }
        end
      end
    end

    context 'when the api answer is invalid' do
      let(:cassette) { 'api_particulier/success/etudiants_invalid' }

      context 'when no sources is requested' do
        let(:requested_sources) { {} }

        it { expect { subject }.to raise_error(APIParticulier::MesriAdapter::InvalidSchemaError) }
      end
    end
  end
end
