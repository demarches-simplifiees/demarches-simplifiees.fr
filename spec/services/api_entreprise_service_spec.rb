describe APIEntrepriseService do
  shared_examples 'schedule fetch of all etablissement params' do
    [
      APIEntreprise::EntrepriseJob, APIEntreprise::ExtraitKbisJob, APIEntreprise::TvaJob,
      APIEntreprise::AssociationJob, APIEntreprise::ExercicesJob,
      APIEntreprise::EffectifsJob, APIEntreprise::EffectifsAnnuelsJob, APIEntreprise::AttestationSocialeJob,
      APIEntreprise::BilansBdfJob
    ].each do |job|
      it "should enqueue #{job.class.name}" do
        expect { subject }.to have_enqueued_job(job)
      end
    end
  end

  describe '#create_etablissement' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(body: etablissements_body, status: etablissements_status)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siret[0..8]}/)
        .to_return(body: entreprises_body, status: entreprises_status)
    end

    let(:siret) { '30613890001294' }
    let(:raison_sociale) { "DIRECTION INTERMINISTERIELLE DU NUMERIQUE" }
    let(:etablissements_status) { 200 }
    let(:etablissements_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
    let(:entreprises_status) { 200 }
    let(:entreprises_body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }
    let(:valid_token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }
    let(:procedure) { create(:procedure, api_entreprise_token: valid_token) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:subject) { APIEntrepriseService.create_etablissement(dossier, siret, procedure.id) }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return([])
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when service is up' do
      it 'should fetch etablissement params' do
        expect(subject[0][:siret]).to eq(siret)
      end

      it 'should fetch entreprise params' do
        expect(subject[0][:entreprise_raison_sociale]).to eq(raison_sociale)
      end

      it_behaves_like 'schedule fetch of all etablissement params'
    end

    context 'when etablissement api down' do
      let(:etablissements_status) { 504 }
      let(:etablissements_body) { '' }

      it 'should raise APIEntreprise::API::Error::RequestFailed' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::RequestFailed)
      end
    end

    context 'when etablissement not found' do
      let(:etablissements_status) { 404 }
      let(:etablissements_body) { '' }

      it 'should return nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#create_etablissement_as_degraded_mode' do
    let(:siret) { '41816609600051' }
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:user_id) { 12 }

    subject(:etablissement) { APIEntrepriseService.create_etablissement_as_degraded_mode(dossier, siret, user_id) }

    it 'should create an etablissement with minimumal attributes' do
      etablissement = subject

      expect(etablissement.siret).to eq(siret)
      expect(etablissement).to be_as_degraded_mode
    end

    it_behaves_like 'schedule fetch of all etablissement params'
  end

  describe "#api_insee_up?" do
    subject { described_class.fr_api_insee_up? }
    let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read }
    let(:status) { 200 }

    before do
      stub_request(:get, "https://entreprise.api.gouv.fr/ping/insee/sirene")
        .to_return(body: body, status: status)
    end

    it "returns true when api etablissement is up" do
      expect(subject).to be_truthy
    end

    context "when api entreprise is down" do
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read.gsub('ok', 'HASISSUES') }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when api entreprise status is unknown" do
      let(:body) { "" }
      let(:status) { 0 }

      it "returns nil" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#api_insee_up? for pf" do
    subject { described_class.api_insee_up? }

    let(:body) { File.read('spec/fixtures/files/api_entreprise/i-taiete_status.xml') }
    let(:status) { 200 }

    context "when api entreprise is up" do
      before do
        stub_request(:get, API_ISPF_URL).to_return(body: body, status: status)
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when api entreprise is down" do
      before do
        stub_request(:get, API_ISPF_URL).to_timeout
      end

      it "returns false" do
        expect(subject).to be_falsy
      end
    end
  end
end
