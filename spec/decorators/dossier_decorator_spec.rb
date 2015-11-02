require 'spec_helper'

describe DossierDecorator do
  let(:dossier) { create(:dossier, :with_user, updated_at: Time.new(2015, 12, 24, 14, 10)) }
  subject { dossier.decorate }

  describe 'last_update' do
    subject { super().last_update }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'state_fr' do
    subject{ super().state_fr }

    it 'draft is brouillon' do
      dossier.draft!
      expect(subject).to eq('Brouillon')
    end

    it 'submitted is submit' do
      dossier.submitted!
      expect(subject).to eq('Soumis')
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
      expect(subject).to eq('Validé')
    end

    it 'submit_validated is dépose' do
      dossier.submit_validated!
      expect(subject).to eq('Déposé')
    end

    it 'processed is traité' do
      dossier.processed!
      expect(subject).to eq('Traité')
    end
  end
end
