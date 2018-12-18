require 'spec_helper'

describe Helpscout::UserConversationsAdapter do
  describe '#reports', vcr: { cassette_name: 'helpscout_conversations_reports' } do
    let(:from) { Date.new(2017, 11) }
    let(:to)   { Date.new(2017, 12) }

    before { Rails.cache.clear }

    subject { described_class.new(from, to) }

    it 'returns one report result per month' do
      expect(subject.reports.count).to eq 2
    end

    it 'populates each report with data' do
      expect(subject.reports.first[:conversations_count]).to be > 0
      expect(subject.reports.first[:start_date]).to eq Time.utc(2017, 11)
      expect(subject.reports.first[:end_date]).to eq Time.utc(2017, 12)

      expect(subject.reports.last[:conversations_count]).to be > 0
      expect(subject.reports.last[:start_date]).to eq Time.utc(2017, 12)
      expect(subject.reports.last[:end_date]).to eq Time.utc(2018, 01)
    end
  end
end
