describe FranceConnectParticulierClient do
  describe '#initialize' do
    let(:default_identifier) { Rails.application.secrets.france_connect_particulier[:identifier] }
    let(:default_secret) { Rails.application.secrets.france_connect_particulier[:secret] }

    context 'without params' do
      subject { FranceConnectParticulierClient.new }

      it { expect(subject).to be_instance_of(FranceConnectParticulierClient) }
      it { expect(subject.authorization_code).to be_nil }
      it { expect(subject.identifier).to eql default_identifier }
      it { expect(subject.secret).to eql default_secret }
    end
    context 'when given code in params' do
      let(:code) { 'plop' }

      subject { FranceConnectParticulierClient.new(code) }

      it { expect(subject).to be_instance_of(FranceConnectParticulierClient) }
      it { expect(subject.authorization_code).to eql(code) }
      it { expect(subject.identifier).to eql default_identifier }
      it { expect(subject.secret).to eql default_secret }
    end

    context 'when credentials are given' do
      let(:code) { nil }
      let(:identifier) { SecureRandom.uuid }
      let(:secret) { SecureRandom.uuid }
      let(:credentials) { { identifier: identifier, secret: secret } }

      subject { FranceConnectParticulierClient.new(code, credentials) }

      it { expect(subject).to be_instance_of(FranceConnectParticulierClient) }
      it { expect(subject.authorization_code).to be_nil }
      it { expect(subject.identifier).to eql(identifier) }
      it { expect(subject.secret).to eql(secret) }
    end
  end
end
