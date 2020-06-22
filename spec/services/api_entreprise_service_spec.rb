describe ApiEntrepriseService do
  describe '#create_etablissement' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(body: etablissements_body, status: etablissements_status)
    end

    let(:siret) { '41816609600051' }
    let(:etablissements_status) { 200 }
    let(:etablissements_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
    let(:procedure) { create(:procedure, api_entreprise_token: 'un-jeton') }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:subject) { ApiEntrepriseService.create_etablissement(dossier, siret, procedure.id) }

    before do
      allow_any_instance_of(ApiEntrepriseToken).to receive(:roles).and_return([])
      allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when service is up' do
      it 'should fetch etablissement params' do
        expect(subject[:siret]).to eq(siret)
      end

      [
        ApiEntreprise::EntrepriseJob, ApiEntreprise::AssociationJob, ApiEntreprise::ExercicesJob,
        ApiEntreprise::EffectifsJob, ApiEntreprise::EffectifsAnnuelsJob, ApiEntreprise::AttestationSocialeJob,
        ApiEntreprise::BilansBdfJob
      ].each do |job|
        it "should enqueue #{job.class.name}" do
          expect { subject }.to have_enqueued_job(job)
        end
      end
    end

    context 'when etablissement api down' do
      let(:etablissements_status) { 504 }
      let(:etablissements_body) { '' }

      it 'should raise ApiEntreprise::API::RequestFailed' do
        expect { subject }.to raise_error(ApiEntreprise::API::RequestFailed)
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
end
