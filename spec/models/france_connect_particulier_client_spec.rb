require 'spec_helper'

describe FranceConnectParticulierClient do
  describe '.initialize' do
    it 'create an openid client' do
      expect(described_class).to be < OpenIDConnect::Client
    end
    context 'when given code in params' do
      let(:code) { 'plop' }
      subject { described_class.new(code) }
      it 'set authorisation code' do
        expect_any_instance_of(described_class).to receive(:authorization_code=).with(code)
        described_class.new(code)
      end
    end
  end
end
