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

  describe 'state_fr' do
    subject{ super().display_state }

    it 'brouillon is brouillon' do
      dossier.brouillon!
      expect(subject).to eq('Brouillon')
    end

    it 'en_construction is En construction' do
      dossier.en_construction!
      expect(subject).to eq('En construction')
    end

    it 'accepte is traité' do
      dossier.accepte!
      expect(subject).to eq('Accepté')
    end

    it 'en_instruction is reçu' do
      dossier.en_instruction!
      expect(subject).to eq('En instruction')
    end

    it 'sans_suite is traité' do
      dossier.sans_suite!
      expect(subject).to eq('Sans suite')
    end

    it 'refuse is traité' do
      dossier.refuse!
      expect(subject).to eq('Refusé')
    end
  end
end
