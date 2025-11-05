# frozen_string_literal: true

describe APIParticulier::CnafAdapter do
  let(:adapter) { described_class.new(api_particulier_token, numero_allocataire, code_postal, requested_sources) }

  before { stub_const("API_PARTICULIER_URL", "https://particulier.api.gouv.fr/api") }

  describe '#to_params' do
    let(:api_particulier_token) { '29eb50b65f64e8e00c0847a8bbcbd150e1f847' }
    let(:numero_allocataire) { '5843972' }
    let(:code_postal) { '92110' }

    subject { VCR.use_cassette(cassette) { adapter.to_params } }

    context 'when the api answer is valid' do
      let(:cassette) { "api_particulier/success/composition_familiale" }

      context 'when the token has all the  cnaf scopes' do
        context 'and all the sources are requested' do
          let(:requested_sources) do
            {
              'cnaf' => {
                'allocataires' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
                'enfants' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
                'adresse' => ['identite', 'complementIdentite', 'complementIdentiteGeo', 'numeroRue', 'lieuDit', 'codePostalVille', 'pays'],
                'quotient_familial' => ['quotientFamilial', 'annee', 'mois'],
              },
            }
          end

          let(:result) { JSON.parse(File.read('spec/fixtures/files/api_particulier/composition_familiale.json')) }

          it { is_expected.to eq(result) }
        end

        context 'when no sources is requested' do
          let(:requested_sources) { {} }

          it { is_expected.to eq({}) }
        end

        context 'when a scalar is requested' do
          let(:requested_sources) { { 'cnaf' => { 'adresse' => ['pays'] } } }

          it { is_expected.to eq({ "adresse" => { "pays" => "FRANCE" } }) }
        end

        context 'when a quotient_familial is requested' do
          let(:requested_sources) { { 'cnaf' => { 'quotient_familial' => ['annee'] } } }

          it { is_expected.to eq({ "quotient_familial" => { "annee" => 2021 } }) }
        end

        context 'when a vector is requested' do
          let(:requested_sources) { { 'cnaf' => { 'allocataires' => ['nomPrenom'] } } }

          it { is_expected.to eq({ "allocataires" => [{ "nomPrenom" => "ERIC SNOW" }, { "nomPrenom" => "SANSA SNOW" }] }) }
        end
      end
    end

    context 'when the api answer is invalid' do
      let(:cassette) { "api_particulier/success/composition_familiale_invalid" }

      context 'when no sources is requested' do
        let(:requested_sources) { {} }

        it { expect { subject }.to raise_error(APIParticulier::CnafAdapter::InvalidSchemaError) }
      end
    end
  end
end
