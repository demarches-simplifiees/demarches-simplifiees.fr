# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob, type: :job do
  let!(:procedure) { create(:procedure, :published, :with_service, :with_type_de_champ, estimated_dossiers_count: 4) }
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

    it 'removes gzip file even if an error occurred (re-raises for sidekiq retry)' do
      procedure.libelle = nil
      procedure.save(validate: false)

      expect { subject }.to raise_error(DemarchesPubliquesExportService::Error)
      expect(Dir.glob("*demarches.json.gz", base: 'tmp').empty?).to be_truthy
    end

    it 'closes the gzip file when the upload fails' do
      stub.to_return(status: 500)
      uploaded_io = nil
      allow(APIDatagouv::API).to receive(:upload).and_wrap_original { |original, io, *args| original.call(uploaded_io = io, *args) }

      expect { subject }.to raise_error(APIDatagouv::API::RequestFailed)
      expect(uploaded_io).to be_closed
    end
  end

  describe '#schedulable?' do
    context "when Rails.application.config.ds_opendata_enabled == 'enabled'" do
      it 'is schedulable' do
        Rails.application.config.ds_opendata_enabled = 'enabled'
        expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.schedulable?).to be_truthy
      end
    end
    context "when Rails.application.config.ds_opendata_enabled != 'enabled'" do
      it 'is schedulable' do
        Rails.application.config.ds_opendata_enabled = nil
        expect(Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob.schedulable?).to be_falsy
      end
    end
  end
end
