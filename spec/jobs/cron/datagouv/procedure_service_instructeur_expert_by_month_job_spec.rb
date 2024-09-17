# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ProcedureServiceInstructeurExpertByMonthJob, type: :job do
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe '#perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::ProcedureServiceInstructeurExpertByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    let!(:procedure) { create(:procedure, :published, estimated_dossiers_count: 300, opendata: true, service:) }
    let!(:service) { create(:service) }
    let!(:groupe_instructeur) { procedure.defaut_groupe_instructeur }
    let!(:assign_to) { create(:assign_to, groupe_instructeur:, instructeur:) }
    let!(:instructeur) { create(:instructeur) }
    let!(:experts_procedure) { create(:experts_procedure, procedure:, expert:) }
    let!(:expert) { create(:expert) }

    subject { Cron::Datagouv::ProcedureServiceInstructeurExpertByMonthJob.new.data }

    context 'when all conditions are met' do
      it 'returns the correct data and structure' do
        expect(subject).to match_array(
          [[procedure.id, '35600082800018', 1, 1, 1]]
        )
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
  end
end
