# frozen_string_literal: true

RSpec.describe ReferentielService, type: :service do
  describe '.test' do
    let(:api_referentiel) { build(:api_referentiel, url:, test_data:) }
    let(:url) { "https://api.fr/{id}/" }
    let(:test_data) { "kthxbye" }
    subject { described_class.new(referentiel: api_referentiel).test }

    context 'when referentiel works', vcr: 'referentiel/test' do
      it { is_expected.to eq(true) }
      it 'update referentiel.last_response and body' do
        expect { subject }.to change { api_referentiel.last_response }.from(nil).to({ "status" => 200, "body" => {} })
      end
    end

    context "when referentiel does not works", vcr: 'referentiel/ko' do
      it "update referentiel.last_response with status and body" do
        expect { subject }.to change { api_referentiel.last_response }.from(nil).to({ "body" => nil, "status" => 404 })
      end
    end
  end
end
