require 'spec_helper'

describe DossierDecorator do
  let(:dossier) { create(:dossier, created_at: Time.new(2015, 12, 24, 14, 10), updated_at: Time.new(2015, 12, 24, 14, 10)) }
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

    it 'draft is brouillon' do
      dossier.draft!
      expect(subject).to eq('Brouillon')
    end

    it 'initiated is initiate' do
      dossier.initiated!
      expect(subject).to eq('Nouveau')
    end

    it 'replied is repondu' do
      dossier.replied!
      expect(subject).to eq('Répondu')
    end

    it 'updated is mis à jour' do
      dossier.updated!
      expect(subject).to eq('Mis à jour')
    end

    it 'validated is valide' do
      dossier.validated!
      expect(subject).to eq('Figé')
    end

    it 'submitted is dépose' do
      dossier.submitted!
      expect(subject).to eq('Déposé')
    end

    it 'closed is traité' do
      dossier.closed!
      expect(subject).to eq('Accepté')
    end

    it 'received is reçu' do
      dossier.received!
      expect(subject).to eq('Reçu')
    end

    it 'without_continuation is traité' do
      dossier.without_continuation!
      expect(subject).to eq('Sans suite')
    end

    it 'refused is traité' do
      dossier.refused!
      expect(subject).to eq('Refusé')
    end
  end
end
