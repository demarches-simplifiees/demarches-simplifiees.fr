# frozen_string_literal: true

describe FranceConnectService do
  describe '.authorization_uri' do
    let(:client) { instance_double('OpenIDConnect::Client') }
    let(:state) { 'a_state' }
    let(:nonce) { 'a_nonce' }
    let(:uri) { 'a_uri' }

    subject { described_class.authorization_uri }

    before do
      stub_const('FRANCE_CONNECT', identifier: 'identifier')
      allow(OpenIDConnect::Client).to receive(:new).and_return(client)
      allow(SecureRandom).to receive(:alphanumeric).with(32).and_return(state, nonce)
      allow(client).to receive(:authorization_uri).with(
        scope: [:profile, :email],
        state:, nonce:, acr_values: 'eidas1'
      )
        .and_return(uri)
    end

    it 'returns authorization uri' do
      expect(subject).to eq([uri, state, nonce])
    end
  end

  describe '.retrieve_user_informations' do
    let(:code) { 'plop' }
    let(:given_name) { 'plop1' }
    let(:family_name) { 'plop2' }
    let(:birthdate) { '2012-12-31' }
    let(:gender) { 'plop4' }
    let(:birthplace) { 'plop5' }
    let(:email) { 'plop@emaiL.com' }
    let(:phone) { '012345678' }
    let(:france_connect_particulier_id) { 'izhikziogjuziegj' }
    let(:nonce) { 'a_nonce' }

    let(:user_info_hash) { { sub: france_connect_particulier_id, given_name:, family_name:, birthdate:, gender:, birthplace:, email:, phone: } }
    let(:user_info) { instance_double('OpenIDConnect::ResponseObject::UserInfo', raw_attributes: user_info_hash) }

    subject { described_class.find_or_retrieve_france_connect_information(code, nonce) }

    before do
      access_token = instance_double('OpenIDConnect::AccessToken')
      allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!).and_return(access_token)
      allow(access_token).to receive(:userinfo!).and_return(user_info)
      allow(access_token).to receive(:id_token).and_return('id_token')

      allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode).and_return(double(verify!: true))
      stub_const('FRANCE_CONNECT', identifier: 'identifier')
    end

    it 'returns user informations' do
      fci, id_token = subject

      expect(fci).to have_attributes({
        given_name: given_name,
        family_name: family_name,
        birthdate: Time.zone.parse(birthdate).to_date,
        birthplace: birthplace,
        gender: gender,
        email_france_connect: email,
        france_connect_particulier_id: france_connect_particulier_id,
      })

      expect(id_token).to eq('id_token')
    end
  end
end
