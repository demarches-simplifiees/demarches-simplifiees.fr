RSpec.describe Cron::Datagouv::InstructeurConnectedByMonthJob, type: :job do
  let!(:user) { create(:user) }
  let!(:instructeur) { create(:instructeur, user: user, created_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::InstructeurConnectedByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end
end
