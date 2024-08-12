RSpec.describe Cron::Datagouv::InstructionTimeByMonthJob, type: :job do
  let!(:user) { create(:user, created_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe '#perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::InstructionTimeByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    let!(:date) { Date.today.prev_month.beginning_of_month }
    let!(:procedure) { create(:procedure, :published, estimated_dossiers_count: 20, opendata: true) }
    let!(:dossier) { create(:dossier, state: :brouillon, created_at: date, depose_at: date + 1, en_instruction_at: date + 2, processed_at: date + 3, procedure:) }

    subject { Cron::Datagouv::InstructionTimeByMonthJob.new.data }

    context 'when all conditions are met' do
      it 'returns the correct data and structure' do
        expect(subject).to match_array(
          [[procedure.id, date.iso8601, (date + 1).iso8601, (date + 2).iso8601, (date + 3).iso8601]]
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
        procedure.update(estimated_dossiers_count: 19)
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

    context 'when the dossier is older than last month' do
      before do
        dossier.update(created_at: 2.months.ago)
      end

      it 'does not count the dossier' do
        expect(subject).to be_empty
      end
    end
  end
end
