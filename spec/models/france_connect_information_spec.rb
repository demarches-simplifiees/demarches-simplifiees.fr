require 'spec_helper'

describe FranceConnectInformation, type: :model do
  describe 'validation' do
    context 'france_connect_particulier_id' do
      it { is_expected.not_to allow_value(nil).for(:france_connect_particulier_id) }
      it { is_expected.not_to allow_value('').for(:france_connect_particulier_id) }
      it { is_expected.to allow_value('mon super projet').for(:france_connect_particulier_id) }
    end
  end
end
