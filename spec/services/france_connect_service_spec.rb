require 'spec_helper'

describe FranceConnectService do

  describe '.retrieve_user_informations' do
    let(:code) { 'plop' }

    it 'set code for FranceConnectClient' do
      expect_any_instance_of(FranceConnectClient).to receive(:initialize).with(code: code)
      described_class.retrieve_user_informations code
    end
  end
end