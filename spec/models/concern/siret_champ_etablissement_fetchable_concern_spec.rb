RSpec.describe SiretChampEtablissementFetchableConcern do
  describe '.fetch_etablissement!' do
    let(:api_etablissement_status) { 200 }
    let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
    let(:token_expired) { false }
    let!(:champ) { create(:champ_siret) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}/)
        .to_return(status: api_etablissement_status, body: api_etablissement_body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles)
        .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(token_expired)
    end

    subject(:fetch_etablissement!) { champ.fetch_etablissement!(siret, build_stubbed(:user)) }

    shared_examples 'an error occured' do |error|
      it { expect { fetch_etablissement! }.to change { champ.reload.value }.to('') }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement }.to(nil) }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(-1) }

      it { expect(fetch_etablissement!).to eq(error) }
    end

    context 'when the SIRET is empty' do
      let(:siret) { '' }

      it_behaves_like 'an error occured', nil
    end

    context 'when the SIRET is invalid' do
      let(:siret) { '1234' }

      it_behaves_like 'an error occured', :invalid
    end

    context 'when the API is unavailable due to network error' do
      let(:siret) { '82161143100015' }
      let(:api_etablissement_status) { 503 }

      before { expect(APIEntrepriseService).to receive(:api_up?).and_return(true) }

      it_behaves_like 'an error occured', :network_error

      it 'sends the error to Sentry' do
        expect(Sentry).to receive(:capture_exception)
        fetch_etablissement!
      end
    end

    context 'when the API is unavailable due to an api maintenance or pb' do
      let(:siret) { '82161143100015' }
      let(:api_etablissement_status) { 502 }

      before { expect(APIEntrepriseService).to receive(:api_up?).and_return(false) }

      it { expect { fetch_etablissement! }.to change { champ.reload.value }.to(siret) }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement } }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.as_degraded_mode? }.to(true) }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(1) }

      it { expect(fetch_etablissement!).to eq(:api_entreprise_down) }
    end

    context 'when the SIRET is valid but unknown' do
      let(:siret) { '00000000000000' }
      let(:api_etablissement_status) { 404 }

      it_behaves_like 'an error occured', :not_found
    end

    context 'when the SIRET informations are retrieved successfully' do
      let(:siret) { '41816609600051' }
      let(:api_etablissement_status) { 200 }
      let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

      it { expect { fetch_etablissement! }.to change { champ.reload.value }.to(siret) }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.siret }.to(siret) }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.naf }.to("6202A") }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(1) }

      it { expect(fetch_etablissement!).to eq(siret) }
    end
  end
end
