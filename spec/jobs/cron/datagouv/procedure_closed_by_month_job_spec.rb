# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ProcedureClosedByMonthJob, type: :job do
  let!(:procedure) { create(:procedure, closed_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::ProcedureClosedByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end
end
