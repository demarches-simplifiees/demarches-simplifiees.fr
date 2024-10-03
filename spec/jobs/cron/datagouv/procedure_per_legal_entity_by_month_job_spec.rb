# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ProcedurePerLegalEntityByMonthJob, type: :job do
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe '#perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::ProcedurePerLegalEntityByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    let!(:procedure) { create(:procedure, :published, for_individual: false, estimated_dossiers_count: 300, opendata: true) }
    let!(:dossier) { create(:dossier, depose_at: 1.month.ago, procedure:) }
    let!(:etablissement) { create(:etablissement, dossier:) }

    subject { Cron::Datagouv::ProcedurePerLegalEntityByMonthJob.new.data }

    context 'when all conditions are met' do
      it 'returns the correct data and structure' do
        expect(subject).to match_array(
          [[procedure.id, etablissement.siret, dossier.depose_at]]
        )
      end
    end

    context 'when the procedure is for individual' do
      before do
        procedure.update(for_individual: true)
      end

      it 'does not include the procedure' do
        expect(subject).to be_empty
      end
    end

    context 'when the procedure is not opendata' do
      before do
        procedure.update(opendata: false)
      end

      it 'does not include the procedure' do
        expect(subject).to be_empty
      end
    end

    context 'when the procedure has insufficient number of dossiers' do
      before do
        procedure.update(estimated_dossiers_count: 299)
      end

      it 'does not include the procedure' do
        expect(subject).to be_empty
      end
    end

    context 'when the procedure has several revisions' do
      before do
        procedure.publish_revision!
      end

      it 'only considers the published revision' do
        expect(subject).to be_empty
      end
    end

    context 'when the file has not been deposed during the previous month' do
      it 'does not include the file' do
        dossier.update(depose_at: Date.current.beginning_of_month.to_time)
        expect(subject).to be_empty
        dossier.update(depose_at: 2.months.ago)
        expect(subject).to be_empty
      end
    end
  end
end
