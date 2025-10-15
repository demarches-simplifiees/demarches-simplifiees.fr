# frozen_string_literal: true

describe Champs::SiretChamp do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:, etablissement:) } }
  let(:value) { "" }
  let(:etablissement) { nil }

  describe '#validate' do
    subject { champ.tap { _1.validate(:champs_public_value) } }

    context 'when empty' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context 'with invalid format' do
      let(:value) { "12345" }

      it { subject.errors[:value].should include('doit comporter exactement 14 chiffres. Exemple : 500 001 234 56789') }
    end

    context 'with invalid checksum' do
      let(:value) { "12345678901234" }

      it { subject.errors[:value].should include("comporte une erreur de saisie. Corrigez-la.") }
    end

    context 'with valid format but no etablissement' do
      let(:value) { "12345678901245" }

      it { subject.errors[:value].should include("ne correspond pas à un établissement existant") }
    end

    context 'with valid SIRET and etablissement' do
      let(:value) { "12345678901245" }
      let(:etablissement) { build(:etablissement, siret: value) }

      it { is_expected.to be_valid }
    end
  end

  describe '.fetch_etablissement!' do
    let(:api_etablissement_status) { 200 }
    let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
    let(:token_expired) { false }
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let!(:champ) { dossier.champs.first.tap { _1.update!(etablissement: create(:etablissement)) } }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(status: api_etablissement_status, body: api_etablissement_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret[0..8]}/)
        .to_return(body: File.read('spec/fixtures/files/api_entreprise/entreprises.json'), status: 200)
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles)
        .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
    end

    subject(:fetch_etablissement!) { champ.fetch_etablissement!(siret, build_stubbed(:user)) }

    shared_examples 'an error occured' do
      it { expect { fetch_etablissement! }.to change { champ.reload.etablissement }.to(nil) }

      it { expect { fetch_etablissement! }.to change { Etablissement.count }.by(-1) }

      it { expect(fetch_etablissement!).to eq(false) }
    end

    context 'when the SIRET is empty' do
      let(:siret) { '' }

      it_behaves_like 'an error occured'
    end

    context "when the SIRET is invalid because of it's length" do
      let(:siret) { '1234' }

      it_behaves_like 'an error occured'
    end

    context "when the SIRET is invalid because of it's checksum" do
      let(:siret) { '82812345600023' }

      it_behaves_like 'an error occured'
    end

    context 'when the API is unavailable due to network error' do
      let(:siret) { '82161143100015' }
      let(:api_etablissement_status) { 503 }

      before { expect(APIEntrepriseService).to receive(:api_insee_up?).and_return(true) }

      it_behaves_like 'an error occured'

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
    end

    context 'when the SIRET is valid but unknown' do
      let(:siret) { '00000000000000' }
      let(:api_etablissement_status) { 404 }

      it_behaves_like 'an error occured'
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
