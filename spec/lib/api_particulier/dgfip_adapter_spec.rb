describe APIParticulier::DgfipAdapter do
  let(:adapter) { described_class.new(api_particulier_token, numero_fiscal, reference_avis, requested_sources) }

  before { stub_const('API_PARTICULIER_URL', 'https://particulier.api.gouv.fr/api') }

  describe '#to_params' do
    let(:api_particulier_token) { '29eb50b65f64e8e00c0847a8bbcbd150e1f847' }
    let(:numero_fiscal) { '2097699999077' }
    let(:reference_avis) { '2097699999077' }

    subject { VCR.use_cassette(cassette) { adapter.to_params } }

    context 'when the api answer is valid' do
      let(:cassette) { 'api_particulier/success/avis_imposition' }

      context 'when the token has all the  dgfip scopes' do
        context 'and all the sources are requested' do
          let(:requested_sources) do
            {
              'dgfip' => {
                'avis_imposition' => [
                  { 'declarant1' => ['dateNaissance', 'nom', 'nomNaissance', 'prenoms'] },
                  { 'declarant2' => ['dateNaissance', 'nom', 'nomNaissance', 'prenoms'] },
                  'anneeImpots',
                  'anneeRevenus',
                  'dateEtablissement',
                  'dateRecouvrement',
                  'erreurCorrectif',
                  'impotRevenuNetAvantCorrections',
                  'montantImpot',
                  'nombreParts',
                  'nombrePersonnesCharge',
                  'revenuBrutGlobal',
                  'revenuFiscalReference',
                  'revenuImposable',
                  'situationFamille',
                  'situationPartielle'
                ],
                'foyer_fiscal' => ['adresse', 'annee']
              }
            }
          end

          let(:result) { JSON.parse(File.read('spec/fixtures/files/api_particulier/avis_imposition.json')) }

          it { is_expected.to eq(result) }
        end

        context 'when no sources is requested' do
          let(:requested_sources) { {} }

          it { is_expected.to eq({}) }
        end

        context 'when a declarer name is requested' do
          let(:requested_sources) { { 'dgfip' => { 'avis_imposition' => [{ 'declarant1' => ['nom'] }] } } }

          it { is_expected.to eq('avis_imposition' => { 'declarant1' => { 'nom' => 'FERRI' } }) }
        end

        context 'when a revenue is requested' do
          let(:requested_sources) { { 'dgfip' => { 'avis_imposition' => ['revenuBrutGlobal'] } } }

          it { is_expected.to eq('avis_imposition' => { 'revenuBrutGlobal' => 38814 }) }
        end
      end
    end

    context 'when the api answer is invalid' do
      let(:cassette) { 'api_particulier/success/avis_imposition_invalid' }

      context 'when no sources is requested' do
        let(:requested_sources) { {} }

        it { expect { subject }.to raise_error(APIParticulier::DgfipAdapter::InvalidSchemaError) }
      end
    end
  end
end
