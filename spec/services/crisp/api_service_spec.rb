# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crisp::APIService do
  let(:service) { described_class.new }
  let(:email) { 'user@example.com' }
  let(:body) { { "key" => "value" } }

  describe '#update_people_data' do
    let(:api_client) { instance_double(API::Client) }
    let(:website_id) { 'test-website-id' }

    before do
      allow(ENV).to receive(:fetch).with("CRISP_WEBSITE_ID").and_return(website_id)
      allow(ENV).to receive(:fetch).with("CRISP_CLIENT_IDENTIFIER").and_return('client-id')
      allow(ENV).to receive(:fetch).with("CRISP_CLIENT_KEY").and_return('client-key')
      allow(API::Client).to receive(:new).and_return(api_client)
    end

    context 'when API call succeeds' do
      before do
        allow(api_client).to receive(:call).and_return(
          Dry::Monads::Success({ body: { "error" => false, reason: "updated", "data": {} } })
        )
      end

      it 'calls API with correct parameters' do
        result = service.update_people_data(email:, body:)

        expect(api_client).to have_received(:call).with(
          url: URI("https://api.crisp.chat/v1/website/#{website_id}/people/data/#{email}"),
          json: body,
          method: :patch,
          headers: { 'X-Crisp-Tier' => 'Plugin' },
          userpwd: 'client-id:client-key'
        )

        expect(result).to be_success
      end
    end

    context 'when API call fails' do
      before do
        allow(api_client).to receive(:call).and_return(
          Dry::Monads::Failure({ code: 400, reason: 'Bad Request' })
        )
      end

      it 'returns failure result' do
        result = service.update_people_data(email:, body:)

        expect(result).to be_failure
      end
    end
  end
end
