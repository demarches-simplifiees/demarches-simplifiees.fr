require 'spec_helper'

describe DossierDecorator do
  let(:dossier) do
    dossier = create(:dossier, created_at: Time.zone.local(2015, 12, 24, 14, 10))
    dossier.update_column('updated_at', Time.zone.local(2015, 12, 24, 14, 10))
    dossier
  end

  subject { dossier.decorate }

  describe 'first_creation' do
    subject { super().first_creation }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'last_update' do
    subject { super().last_update }
    it { is_expected.to eq('24/12/2015 14:10') }
  end
end
