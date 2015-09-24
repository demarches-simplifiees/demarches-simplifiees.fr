require 'spec_helper'

describe DossierDecorator do
  let(:dossier) { create(:dossier, :with_user) }
  subject { dossier.decorate }
  describe 'last_update' do
    subject { Timecop.freeze(Time.new(2015, 12, 24, 14, 10)) { super().last_update } }
    it { is_expected.to eq('24/12/2015 14:10') }
  end
end
