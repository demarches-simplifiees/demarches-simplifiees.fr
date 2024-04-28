# frozen_string_literal: true

describe APIParticulier::PoleEmploiAdapter do
  let(:adapter) { described_class.new(api_particulier_token, identifiant, requested_sources) }

  before { stub_const('API_PARTICULIER_URL', 'https://particulier.api.gouv.fr/api') }

  describe '#to_params' do
    let(:api_particulier_token) { '06fd8675601267d2988cbbdef56ecb0de1d45223' }
    let(:identifiant) { 'georges_moustaki_77' }

    subject { VCR.use_cassette(cassette) { adapter.to_params } }

    context 'when the api answer is valid' do
      let(:cassette) { 'api_particulier/success/situation_pole_emploi' }

      context 'when the token has all the pole emploi scopes' do
        context 'and all the sources are requested' do
          let(:requested_sources) do
            {
              'pole_emploi' => {
                'identite' => ['identifiant', 'civilite', 'nom', 'nomUsage', 'prenom', 'sexe', 'dateNaissance'],
                'adresse' => ['INSEECommune', 'codePostal', 'localite', 'ligneVoie', 'ligneComplementDestinataire', 'ligneComplementAdresse', 'ligneComplementDistribution', 'ligneNom'],
                'contact' => ['email', 'telephone', 'telephone2'],
                'inscription' => ['dateInscription', 'dateCessationInscription', 'codeCertificationCNAV', 'codeCategorieInscription', 'libelleCategorieInscription']
              }
            }
          end

          let(:result) { JSON.parse(File.read('spec/fixtures/files/api_particulier/situation_pole_emploi.json')) }

          it { is_expected.to eq(result) }
        end

        context 'when no sources is requested' do
          let(:requested_sources) { {} }

          it { is_expected.to eq({}) }
        end

        context 'when an address name is requested' do
          let(:requested_sources) { { 'pole_emploi' => { 'adresse' => ['ligneNom'] } } }

          it { is_expected.to eq('adresse' => { 'ligneNom' => 'MOUSTAKI' }) }
        end

        context 'when a first name is requested' do
          let(:requested_sources) { { 'pole_emploi' => { 'identite' => ['prenom'] } } }

          it { is_expected.to eq('identite' => { 'prenom' => 'Georges' }) }
        end
      end
    end

    context 'when the api answer is invalid' do
      let(:cassette) { 'api_particulier/success/situation_pole_emploi_invalid' }

      context 'when no sources is requested' do
        let(:requested_sources) { {} }

        it { expect { subject }.to raise_error(APIParticulier::PoleEmploiAdapter::InvalidSchemaError) }
      end
    end
  end
end
