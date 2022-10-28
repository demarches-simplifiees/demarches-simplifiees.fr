RSpec.describe Cron::Datagouv::InstructeurByMonthJob, type: :job do
  let!(:instructeur) { create(:instructeur, created_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::InstructeurByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end
end
