require 'spec_helper'

describe FranceConnectService do

  describe '.retrieve_user_informations' do

    let(:code) { 'plop' }
    let(:access_token) { 'my access_token' }
    let(:email) { 'patator@cake.com' }
    let(:siret) { '41123069100049' }
    let(:user_info_hash) {  {'email' => email, 'siret' => siret} }
    let(:user_info) { instance_double('OpenIDConnect::ResponseObject::UserInfo', raw_attributes: user_info_hash, email: email) }

    subject { described_class.retrieve_user_informations code }

    before do
      allow_any_instance_of(FranceConnectClient).to receive(:access_token!).and_return(access_token)
      allow(access_token).to receive(:userinfo!).and_return(user_info)
    end
    it 'set code for FranceConnectClient' do
      expect_any_instance_of(FranceConnectClient).to receive(:authorization_code=).with(code)
      described_class.retrieve_user_informations code
    end

    it 'returns user informations in a object' do
      expect(subject.email).to eq(email)
      expect(subject.siret).to eq(siret)
    end
  end
end