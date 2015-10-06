require 'spec_helper'

describe FranceConnectClient do
  describe '.initialize' do
    it 'create an openid client' do
      expect(described_class).to be < OpenIDConnect::Client
    end
    context 'when given code in params' do
      let(:code) { 'plop' }
      subject { described_class.new(code: code) }
      it 'set authorisation code' do
        expect_any_instance_of(described_class).to receive(:authorization_code=).with(code)
        described_class.new(code: code)
      end
    end
  end
end