require 'spec_helper'

describe DossierSearchService do
  describe '#matching_dossiers_for_gestionnaire' do
    subject { liste_dossiers }

    let(:liste_dossiers) do
      described_class.matching_dossiers_for_gestionnaire(terms, gestionnaire_1)
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

    let!(:dossier_0) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure_1, user: create(:user, email: 'brouillon@clap.fr')) }

    let!(:etablissement_1) { create(:etablissement, entreprise_raison_sociale: 'OCTO Academy', siret: '41636169600051') }
    let!(:dossier_1) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, user: create(:user, email: 'contact@test.com'), etablissement: etablissement_1) }

    let!(:etablissement_2) { create(:etablissement, entreprise_raison_sociale: 'Plop octo', siret: '41816602300012') }
    let!(:dossier_2) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, user: create(:user, email: 'plop@gmail.com'), etablissement: etablissement_2) }

    let!(:etablissement_3) { create(:etablissement, entreprise_raison_sociale: 'OCTO Technology', siret: '41816609600051') }
    let!(:dossier_3) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_2, user: create(:user, email: 'peace@clap.fr'), etablissement: etablissement_3) }

    let!(:dossier_archived) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, archived: true, user: create(:user, email: 'archived@clap.fr')) }

    describe 'search is empty' do
      let(:terms) { '' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search brouillon file' do
      let(:terms) { 'brouillon' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search archived file' do
      let(:terms) { 'archived' }

      it { expect(subject.size).to eq(1) }
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

    describe 'search terms surrounded with spurious spaces' do
      let(:terms) { ' OCTO ' }

      it { expect(subject.size).to eq(2) }
    end

    describe 'search on multiple fields' do
      let(:terms) { 'octo plop' }

      it { expect(subject.size).to eq(1) }
    end

    describe 'search with characters disallowed by the tsquery parser' do
      let(:terms) { "'?\\:&!(OCTO) <plop>" }

      it { expect(subject.size).to eq(1) }
    end
  end
end
