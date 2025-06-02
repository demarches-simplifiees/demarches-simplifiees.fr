# frozen_string_literal: true

describe Helpscout::UserConversationsAdapter do
  let(:from) { Date.new(2017, 11) }
  let(:to)   { Date.new(2017, 12) }

  describe '#can_fetch_reports?' do
    context 'when a required secret is missing' do
      before do
        Rails.application.secrets.helpscout[:mailbox_id] = nil
      end

      it { expect(described_class.new(from, to).can_fetch_reports?).to be false }
    end

    context 'when all required secrets are present' do
      before do
        mock_helpscout_secrets
      end

      it { expect(described_class.new(from, to).can_fetch_reports?).to be true }
    end
  end

  describe '#reports', vcr: { cassette_name: 'helpscout_conversations_reports' } do
    before do
      mock_helpscout_secrets
      Rails.cache.clear
    end

    subject { described_class.new(from, to) }

    it 'returns one report result per month' do
      expect(subject.reports.count).to eq 2
    end

    it 'populates each report with data' do
      expect(subject.reports.first[:replies_sent]).to be > 0
      expect(subject.reports.first[:start_date]).to eq Time.utc(2017, 11)
      expect(subject.reports.first[:end_date]).to eq Time.utc(2017, 12)

      expect(subject.reports.last[:replies_sent]).to be > 0
      expect(subject.reports.last[:start_date]).to eq Time.utc(2017, 12)
      expect(subject.reports.last[:end_date]).to eq Time.utc(2018, 01)
    end
  end

  def mock_helpscout_secrets
    Rails.application.secrets.helpscout[:mailbox_id] = '9999'
    Rails.application.secrets.helpscout[:client_id] = '1234'
    Rails.application.secrets.helpscout[:client_secret] = '5678'
  end
end
