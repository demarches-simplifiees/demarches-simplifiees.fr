require 'spec_helper'

describe FranceConnectSaltService do
  describe '.initialize' do
    context 'when args is not a FranceConnectInformation class' do
      let(:args) { create(:dossier) }

      subject { described_class.new args }

      it { expect { subject }.to raise_error 'Not a FranceConnectInformation class' }
    end
  end

  describe '.valid?' do
    let(:france_connect_information) { create(:france_connect_information) }
    let(:salt_service) { FranceConnectSaltService.new(france_connect_information) }
    let(:salt) { salt_service.salt }

    context 'when france_connect_information_id is correct' do
      let(:france_connect_information_id) { france_connect_information.id }
      let(:france_connect_information_get_with_id) { FranceConnectInformation.find(france_connect_information_id) }
      let(:salt_service_compare) { FranceConnectSaltService.new france_connect_information_get_with_id }

      subject { salt_service_compare.valid? salt }

      it { is_expected.to be_truthy }
    end

    context 'when france_connect_information_id is not correct' do
      let(:france_connect_information_fake) { create(:france_connect_information, france_connect_particulier_id: '87515272') }

      let(:france_connect_information_id) { france_connect_information_fake.id }
      let(:france_connect_information_get_with_id) { FranceConnectInformation.find(france_connect_information_id) }
      let(:salt_service_compare) { FranceConnectSaltService.new france_connect_information_get_with_id }

      subject { salt_service_compare.valid? salt }

      it { is_expected.to be_falsey }
    end
  end
end