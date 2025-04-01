# frozen_string_literal: true

describe FranceConnectParticulierClient do
  describe '#initialize' do
    subject { FranceConnectParticulierClient.new(code) }

    context 'when given code in params' do
      let(:code) { 'plop' }

      before do
        stub_const('FRANCE_CONNECT', identifier: 'identifier')
        allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_code=)
      end

      it { is_expected.to have_received(:authorization_code=).with(code) }
    end
  end
end
