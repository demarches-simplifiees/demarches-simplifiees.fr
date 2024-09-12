# frozen_string_literal: true

RSpec.describe Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob, type: :job do
  let!(:user) { create(:user, created_at: 1.month.ago, loged_in_with_france_connect: "particulier") }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    subject { Cron::Datagouv::UserConnectedWithFranceConnectByMonthJob.new.data }

    it 'returns the correct data and structure' do
      expect(subject).to match_array([[1]])
    end

    context 'when the user has not been not created during the previous month' do
      it 'does not include the file' do
        user.update(created_at: Date.current.beginning_of_month.to_time)
        expect(subject).to match_array([[0]])
        user.update(created_at: 2.months.ago)
        expect(subject).to match_array([[0]])
      end
    end

    context 'when the user was not connected with FranceConnect' do
      before do
        user.update(loged_in_with_france_connect: nil)
      end

      it 'does not include the file' do
        expect(subject).to match_array([[0]])
      end
    end
  end
end
