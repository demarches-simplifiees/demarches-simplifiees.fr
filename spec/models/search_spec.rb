require 'spec_helper'

describe Search do
  describe '.results' do
    subject { liste_dossiers }

    let(:liste_dossiers) do
      described_class.new(gestionnaire: gestionnaire_1, query: terms).results
    end

    let(:administrateur_1) { create(:administrateur) }
    let(:administrateur_2) { create(:administrateur) }

    let(:gestionnaire_1) { create(:gestionnaire, administrateurs: [administrateur_1]) }
    let(:gestionnaire_2) { create(:gestionnaire, administrateurs: [administrateur_2]) }

    before do
      create :assign_to, gestionnaire: gestionnaire_1, procedure: procedure_1
      create :assign_to, gestionnaire: gestionnaire_2, procedure: procedure_2
    end

    let(:procedure_1) { create(:procedure, :published, administrateur: administrateur_1) }
    let(:procedure_2) { create(:procedure, :published, administrateur: administrateur_2) }

    let!(:dossier_0) { create(:dossier, state: 'brouillon', procedure: procedure_1, user: create(:user, email: 'brouillon@clap.fr')) }
    let!(:dossier_1) { create(:dossier, state: 'en_construction', procedure: procedure_1, user: create(:user, email: 'contact@test.com')) }
    let!(:dossier_2) { create(:dossier, state: 'en_construction', procedure: procedure_1, user: create(:user, email: 'plop@gmail.com')) }
    let!(:dossier_3) { create(:dossier, state: 'en_construction', procedure: procedure_2, user: create(:user, email: 'peace@clap.fr')) }
    let!(:dossier_archived) { create(:dossier, state: 'en_construction', procedure: procedure_1, archived: true, user: create(:user, email: 'brouillonArchived@clap.fr')) }

    let!(:etablissement_1) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'OCTO Academy', dossier: dossier_1), dossier: dossier_1, siret: '41636169600051') }
    let!(:etablissement_2) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'Plop octo', dossier: dossier_2), dossier: dossier_2, siret: '41816602300012') }
    let!(:etablissement_3) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'OCTO Technology', dossier: dossier_3), dossier: dossier_3, siret: '41816609600051') }

    describe 'search is empty' do
      let(:terms) { '' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search brouillon file' do
      let(:terms) { 'brouillon' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search on contact email' do
      let(:terms) { 'clap' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search on SIRET' do
      context 'when is part of SIRET' do
        let(:terms) { '4181' }

        it { expect(subject.size).to eq(1) }
      end

      context 'when is a complet SIRET' do
        let(:terms) { '41816602300012' }

        it { expect(subject.size).to eq(1) }
      end
    end

    describe 'search on raison social' do
      let(:terms) { 'OCTO' }

      it { expect(subject.size).to eq(2) }
    end

    describe 'search on multiple fields' do
      let(:terms) { 'octo plop' }

      it { expect(subject.size).to eq(1) }
    end
  end
end
