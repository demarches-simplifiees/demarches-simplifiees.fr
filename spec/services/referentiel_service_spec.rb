# frozen_string_literal: true

RSpec.describe ReferentielService, type: :service do
  let(:api_referentiel) { create(:api_referentiel, :configured, url:, test_data:) }
  let(:url) { "https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/" }
  let(:test_data) { "PG46YY6YWCX8" }

  before do
    stub_request(:get, api_referentiel.url.gsub('{id}', query_params))
      .to_return(status:, body: body&.to_json)
  end

  describe '.test either it works, either it does not' do
    let(:query_params) { api_referentiel.test_data }
    subject { described_class.new(referentiel: api_referentiel).test }

    context 'when referentiel works' do
      let(:status) { 200 }
      let(:body) { { rnb_id: api_referentiel.test_data } }
      it { is_expected.to eq(true) }
      it 'update referentiel.last_response and body' do
        expect { subject }.to change { api_referentiel.reload.last_response }.from(nil).to({ status:, body: }.with_indifferent_access)
      end
    end

    context "when referentiel 404 (not found)" do
      let(:status) { 404 }
      let(:body) { nil }

      it "update referentiel.last_response with status and body" do
        expect { subject }.to change { api_referentiel.reload.last_response }.from(nil).to({ status:, body: }.with_indifferent_access)
      end
    end
  end

  describe '.call' do
    include Dry::Monads[:result]

    let(:query_params) { api_referentiel.test_data }
    subject { described_class.new(referentiel: api_referentiel).call(query_params) }

    context "when referentiel 200 success" do
      let(:status) { 200 }
      let(:body) { { body: :ok } }
      it "return a Success" do
        expect(subject).to be_success
      end
    end

    context "when referentiel 404 (not found)" do
      let(:status) { 404 }
      let(:body) { nil }
      it "returns a not retryable Failure" do
        expect(subject).to be_failure
        expect(subject.failure).to include(retryable: false, reason: StandardError.new('Not retryable: 404, 400, 403, 401'), code: 404)
      end
    end

    context "when referentiel 429 (rate limit)" do
      let(:status) { 429 }
      let(:body) { nil }
      it "returns a retryable Failure" do
        expect(subject).to be_failure
        expect(subject.failure).to include(retryable: true, reason: StandardError.new('Retryable: 429, 500, 503, 408, 502'), code: 429)
      end
    end

    context "when referentiel teapots" do
      let(:status) { 418 }
      let(:body) { nil }
      it "returns a retryable Failure" do
        expect(subject).to be_failure
        expect(subject.failure).to include(retryable: false, reason: StandardError.new('Unknown error'), code: 418)
      end
    end
  end
end
