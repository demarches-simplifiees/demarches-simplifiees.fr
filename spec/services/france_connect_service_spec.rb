describe FranceConnectService do
  describe '.enabled?' do
    subject { FranceConnectService.enabled? }

    context 'when FranceConnect is disabled' do
      before(:all) do
        Rails.configuration.x.france_connect.enabled = false
      end

      it { expect(subject).to equal false }
    end

    context 'when FranceConnect is enabled' do
      before(:all) do
        Rails.configuration.x.france_connect.enabled = true
      end

      it { expect(subject).to equal true }
    end
  end

  describe '#authorization_uri' do
    subject { described_class.new.authorization_uri }

    it { expect { Rack::OAuth2::Util.parse_uri(subject) }.not_to raise_exception }

    context 'with default scopes' do
      it 'must contain profile & email scopes' do
        expect(Rails.configuration.x.fcp.scopes).to contain_exactly(:profile, :email)
        expect(subject).to match('profile%20email%20openid')
      end
    end

    context 'with custom scopes' do
      before(:all) do
        @default_scopes = Rails.configuration.x.fcp.scopes
        Rails.configuration.x.fcp.scopes = [:birthdate, :given_name, :family_name, :preferred_username]
      end

      after(:all) do
        Rails.configuration.x.fcp.scopes = @default_scopes
      end

      it 'must contain all the custom scopes' do
        expect(subject).to match('birthdate%20given_name%20family_name%20preferred_username%20openid')
      end
    end
  end

  describe '#find_or_retrieve_france_connect_information' do
    let(:fci) { build(:france_connect_information) }

    subject { described_class.new(code: code).find_or_retrieve_france_connect_information }

    context 'when a code is given' do
      let(:code) { "2401d211-67df-43a0-9d9d-4ec0e01be3f2" }

      it 'returns user informations' do
        VCR.use_cassette("france_connect/success/token", erb: { fc_code: code }) do
          VCR.use_cassette("france_connect/success/userinfo") do
            expect(subject).to have_attributes(fci.attributes.except("created_at", "updated_at"))
          end
        end
      end
    end

    context 'when an invalid code is given' do
      let(:code) { "invalid" }

      it 'returns user informations' do
        VCR.use_cassette("france_connect/error/token", erb: { fc_code: code }) do
          expect { subject }.to raise_exception(Rack::OAuth2::Client::Error)
        end
      end
    end
  end
end
