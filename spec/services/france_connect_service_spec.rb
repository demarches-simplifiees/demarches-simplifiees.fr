require 'spec_helper'

describe FranceConnectService do
  describe '.retrieve_user_informations_entreprise' do
    let(:code) { 'plop' }
    let(:access_token) { 'my access_token' }
    let(:email) { 'patator@cake.com' }
    let(:siret) { '41123069100049' }
    let(:user_info_hash) { {'email' => email, 'siret' => siret} }
    let(:user_info) { instance_double('OpenIDConnect::ResponseObject::UserInfo', raw_attributes: user_info_hash, email: email) }

    subject { described_class.retrieve_user_informations_entreprise code }

    before do
      allow_any_instance_of(FranceConnectEntrepriseClient).to receive(:access_token!).and_return(access_token)
      allow(access_token).to receive(:userinfo!).and_return(user_info)
    end
    it 'set code for FranceConnectEntrepriseClient' do
      expect_any_instance_of(FranceConnectEntrepriseClient).to receive(:authorization_code=).with(code)
      described_class.retrieve_user_informations_entreprise code
    end

    it 'returns user informations in a object' do
      expect(subject.email).to eq(email)
      expect(subject.siret).to eq(siret)
    end
  end

  describe '.retrieve_user_informations_particulier' do
    let(:code) { 'plop' }
    let(:access_token) { 'my access_token' }

    let(:given_name) { 'plop1' }
    let(:family_name) { 'plop2' }
    let(:birthdate) { 'plop3' }
    let(:gender) { 'plop4' }
    let(:birthplace) { 'plop5' }
    let(:email) { 'plop@emaiL.com' }
    let(:phone) { '012345678' }
    let(:france_connect_particulier_id) { 'izhikziogjuziegj' }

    let(:user_info_hash) { {sub: france_connect_particulier_id, given_name: given_name, family_name: family_name, birthdate: birthdate, gender: gender, birthplace: birthplace, email: email, phone: phone} }
    let(:user_info) { instance_double('OpenIDConnect::ResponseObject::UserInfo', raw_attributes: user_info_hash) }

    subject { described_class.retrieve_user_informations_particulier code }

    before do
      allow_any_instance_of(FranceConnectParticulierClient).to receive(:access_token!).and_return(access_token)
      allow(access_token).to receive(:userinfo!).and_return(user_info)
    end

    it 'set code for FranceConnectEntrepriseClient' do
      expect_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_code=).with(code)
      subject
    end

    it 'returns user informations in a object' do
      expect(subject.given_name).to eq(given_name)
      expect(subject.family_name).to eq(family_name)
      expect(subject.birthdate).to eq(birthdate)
      expect(subject.gender).to eq(gender)
      expect(subject.email).to eq(email)
      expect(subject.phone).to eq(phone)
      expect(subject.birthplace).to eq(birthplace)
      expect(subject.france_connect_particulier_id).to eq(france_connect_particulier_id)
    end
  end
end