# frozen_string_literal: true

RSpec.describe Cron::Datagouv::FileDeposeByMonthJob, type: :job do
  let!(:dossier) { create(:dossier, depose_at: 1.month.ago) }
  let(:status) { 200 }
  let(:body) { "ok" }
  let(:stub) { stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/.*\/upload\//) }

  describe 'perform' do
    before do
      stub
    end

    subject { Cron::Datagouv::FileDeposeByMonthJob.perform_now }

    it 'send POST request to datagouv' do
      subject
      expect(stub).to have_been_requested
    end
  end

  describe '#data' do
    subject { Cron::Datagouv::FileDeposeByMonthJob.new.data }

    it 'returns the correct data and structure' do
      expect(subject).to match_array([[1]])
    end

    context 'when the file has not been not created during the previous month' do
      it 'does not include the file' do
        dossier.update(depose_at: Date.current.beginning_of_month.to_time)
        expect(subject).to match_array([[0]])
        dossier.update(depose_at: 2.months.ago)
        expect(subject).to match_array([[0]])
      end
    end

    context 'when there is a deleted file' do
      let!(:deleted_dossier) { create(:deleted_dossier, depose_at: 1.month.ago) }

      it 'does include the file' do
        expect(subject).to match_array([[2]])
      end
    end

    context 'when the file is not visible by user or administration' do
      let!(:dossier_not_visible) { create(:dossier, :hidden_by_expired, depose_at: 1.month.ago) }

      it 'does not include the file' do
        expect(subject).to match_array([[1]])
      end
    end
  end
end
