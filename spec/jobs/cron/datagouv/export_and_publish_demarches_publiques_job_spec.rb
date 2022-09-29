RSpec.describe Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob, type: :job do
  let!(:procedure) { create(:procedure, :published, :with_service, :with_type_de_champ) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.perform_now }

    it 'send POST request to datagouv' do
      subject

      expect(stub).to have_been_requested
    end

    it 'removes gzip file even if an error occured' do
      procedure.libelle = nil
      procedure.save(validate: false)

      expect { subject }.to raise_error(StandardError)
      expect(Dir.glob("*demarches.json.gz", base: 'tmp').empty?).to be_truthy
    end
  end

  describe '#schedulable?' do
    context "when ENV['OPENDATA_ENABLED'] == 'enabled'" do
      it 'is not schedulable' do
        ENV['OPENDATA_ENABLED'] = 'enabled'
        expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.schedulable?).to be_falsy
      end
    end
    context "when ENV['OPENDATA_ENABLED'] != 'enabled'" do
      it 'is not schedulable' do
        ENV['OPENDATA_ENABLED'] = nil
        expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.schedulable?).to be_falsy
      end
    end
  end
end
