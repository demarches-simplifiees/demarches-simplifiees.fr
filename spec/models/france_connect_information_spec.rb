require 'spec_helper'

describe FranceConnectInformation, type: :model do
  describe 'validation' do
    context 'france_connect_particulier_id' do
      it { is_expected.not_to allow_value(nil).for(:france_connect_particulier_id) }
      it { is_expected.not_to allow_value('').for(:france_connect_particulier_id) }
      it { is_expected.to allow_value('mon super projet').for(:france_connect_particulier_id) }
    end
  end

  describe '.find_by_france_connect_particulier' do
    let(:user_info) { {france_connect_particulier_id: '123456'} }

    subject { described_class.find_by_france_connect_particulier user_info }

    context 'when france_connect_particulier_id is prensent in database' do
      let!(:france_connect_information) { create(:france_connect_information, france_connect_particulier_id: '123456') }

      it { is_expected.to eq france_connect_information }
    end

    context 'when france_connect_particulier_id is prensent in database' do
      it { is_expected.to eq nil }
    end
  end
end
