RSpec.describe SiretChampEtablissementFetchableConcern do
  describe '.fetch_etablissement!' do
    let(:api_etablissement_status) { 200 }
    let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
    let(:token_expired) { false }
    let!(:champ) { create(:champ_siret) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(status: api_etablissement_status, body: api_etablissement_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret[0..8]}/)
        .to_return(body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'), status: 200)
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles)
        .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(token_expired)
    end

    subject(:fetch_etablissement!) { champ.fetch_etablissement!(siret, build_stubbed(:user)) }

    shared_examples 'an error occured' do |error|
      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement }.to(nil) }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(-1) }

      it { expect(fetch_etablissement!).to eq(false) }

      it 'populates the etablissement_fetch_error_key' do
        fetch_etablissement!
        expect(champ.etablissement_fetch_error_key).to eq(error)
      end
    end

    context 'when the SIRET is empty' do
      let(:siret) { '' }

      it_behaves_like 'an error occured', :empty
    end

    context "when the SIRET is invalid because of it's length" do
      let(:siret) { '1234' }

      it_behaves_like 'an error occured', :invalid_length
    end

    context "when the SIRET is invalid because of it's checksum" do
      let(:siret) { '82812345600023' }

      it_behaves_like 'an error occured', :invalid_checksum
    end

    context 'when the API is unavailable due to network error' do
      let(:siret) { '82161143100015' }
      let(:api_etablissement_status) { 503 }

      before { expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(true) }

      it_behaves_like 'an error occured', :network_error

      it 'sends the error to Sentry' do
        expect(Sentry).to receive(:capture_exception)
        fetch_etablissement!
      end
    end

    context 'when the API is unavailable due to an api maintenance or pb' do
      let(:siret) { '82161143100015' }
      let(:api_etablissement_status) { 502 }

      before { expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(false) }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement } }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.as_degraded_mode? }.to(true) }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(1) }

      it { expect(fetch_etablissement!).to eq(false) }

      it 'populates the etablissement_fetch_error_key' do
        fetch_etablissement!
        expect(champ.etablissement_fetch_error_key).to eq(:api_entreprise_down)
      end
    end

    context 'when the SIRET is valid but unknown' do
      let(:siret) { '00000000000000' }
      let(:api_etablissement_status) { 404 }

      it_behaves_like 'an error occured', :not_found
    end

    context 'when the SIRET informations are retrieved successfully' do
      let(:siret) { '30613890001294' }
      let(:api_etablissement_status) { 200 }
      let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.siret }.to(siret) }

      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement.naf }.to("8411Z") }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(1) }

      it { expect(fetch_etablissement!).to eq(true) }

      it "fetches the entreprise raison sociale" do
        fetch_etablissement!
        expect(champ.reload.etablissement.entreprise_raison_sociale).to eq("DIRECTION INTERMINISTERIELLE DU NUMERIQUE")
      end
    end
  end
end
