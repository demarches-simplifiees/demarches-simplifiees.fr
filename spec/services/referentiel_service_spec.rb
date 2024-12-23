# frozen_string_literal: true

RSpec.describe ReferentielService, type: :service do
  describe '.test' do
    let(:api_referentiel) { build(:api_referentiel, url:, test_data:) }
    let(:url) { "https://api.fr/{id}/" }
    let(:test_data) { "kthxbye" }

    context 'when referentiel_adapter is url', vcr: 'referentiel/test' do
      subject { described_class.new(referentiel: api_referentiel).test }

      it { is_expected.to eq(true) }
      it 'update referentiel.last_response' do
        expect { subject }.to change { api_referentiel.last_response }.from(nil).to({})
      end
    end
  end
end
