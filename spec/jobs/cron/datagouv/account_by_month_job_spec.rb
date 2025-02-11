# frozen_string_literal: true

RSpec.describe Cron::Datagouv::AccountByMonthJob, type: :job do
  let!(:user) { create(:user, created_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }

  describe 'perform' do

    subject { Cron::Datagouv::AccountByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      allow(APIDatagouv::API).to receive(:upload) do |file|
        csv = CSV.read(file, headers: true)
        expect(csv[0]['mois']).to eq(Date.today.prev_month.strftime("%B %Y"))
      end

      subject
    end
  end
end
