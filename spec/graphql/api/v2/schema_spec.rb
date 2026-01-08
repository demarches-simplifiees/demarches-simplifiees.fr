# frozen_string_literal: true

RSpec.describe API::V2::Schema::Timeout do
  describe '#filter_sensitive_query_string' do
    let(:timeout_instance) { described_class.new(max_seconds: 30) }

    before do
      Rails.application.config.filter_parameters += [:token] unless Rails.application.config.filter_parameters.include?(:token)
    end

    it 'filters sensitive patterns from the query string' do
      query_string = 'query getDemarche($demarcheNumber: Int!) { demarche(number: $demarcheNumber) { id, token } }'
      result = timeout_instance.send(:filter_sensitive_query_string, query_string.dup)

      expect(result).to eq('query getDemarche($demarcheNumber: Int!) { demarche(number: $demarcheNumber) { id, [FILTERED] } }')
    end
  end
end
