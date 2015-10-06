require 'spec_helper'

describe FranceConnectService do

  describe '.retrieve_user_informations' do
    let(:code) { 'plop' }
    let(:mocky) { 'my mocky' }
    let(:user_info) { 'user_informations' }
    subject { described_class.retrieve_user_informations code }
    before do
      allow_any_instance_of(FranceConnectClient).to receive(:access_token!).and_return(mocky)
      allow(mocky).to receive(:userinfo!).and_return(user_info)
    end
    it 'set code for FranceConnectClient' do
      expect_any_instance_of(FranceConnectClient).to receive(:initialize).with(code: code)
      described_class.retrieve_user_informations code
    end

    it 'returns user informations' do
      expect(subject).to eq(user_info)
    end
  end
end