# frozen_string_literal: true

describe DossierSearchService do
  describe '#matching_dossiers' do
    let!(:dossiers) { Dossier.where(id: dossier.id) }

    before { perform_enqueued_jobs(only: DossierIndexSearchTermsJob) }

    def searching(terms) = described_class.matching_dossiers(dossiers, terms)

    describe 'ignores brouillon' do
      let(:dossier) { create(:dossier, state: :brouillon) }

      it { expect(searching(dossier.id.to_s)).to eq([]) }
    end

    context 'with a dossier not in brouillon' do
      let(:user) { create(:user, email: 'nicolas@email.com') }
      let(:etablissement) { create(:etablissement, entreprise_raison_sociale: 'Direction Interministerielle Du Numérique', siret: '13002526500013') }
      let(:dossier) do
        create(:dossier, state: :en_construction, user:, etablissement:).tap do |dossier|
          dossier.champs.first.update!(value: 'Hélène mange des pommes')
        end
      end

      it do
        expect(searching('')).to eq([])

        # by dossier id
        expect(searching(dossier.id.to_s)).to eq([dossier.id])

        # by email
        expect(searching('nicolas@email.com')).to eq([dossier.id])
        expect(searching('nicolas')).to eq([dossier.id])

        # by SIRET
        expect(searching('13002526500013')).to eq([dossier.id])
        expect(searching('1300')).to eq([dossier.id])

        # by raison sociale
        expect(searching('Direction Interministerielle Du Numérique')).to eq([dossier.id])
        expect(searching('Direction')).to eq([dossier.id])

        # with multiple terms
        expect(searching('Direction nicolas')).to eq([dossier.id])

        # with forbidden characters
        expect(searching("'?\\:&!(Direction) <Interministerielle>")).to eq([dossier.id])

        # with supirious spaces
        expect(searching("  nicolas  ")).to eq([dossier.id])

        # with wrong case
        expect(searching('direction')).to eq([dossier.id])

        # by champ text
        expect(searching('Hélène')).to eq([dossier.id])

        # by singular
        expect(searching('la pomme')).to eq([dossier.id])

        # without accent
        expect(searching('helene')).to eq([dossier.id])
      end
    end

    describe 'does not ignore archived dossiers' do
      let(:dossier) { create(:dossier, state: :en_construction, archived: true) }

      it { expect(searching(dossier.id.to_s)).to eq([dossier.id]) }
    end
  end

  describe '#matching_dossiers_for_user' do
    subject { liste_dossiers }

    before do
      dossier_0
      dossier_0b
      dossier_1
      dossier_2
      dossier_3
      dossier_archived
      perform_enqueued_jobs(only: DossierIndexSearchTermsJob)
    end

    let(:liste_dossiers) do
      described_class.matching_dossiers_for_user(terms, user_1)
    end

    let(:user_1) { create(:user, email: 'bidou@clap.fr') }
    let(:user_2) { create(:user) }

    let(:procedure_1) { create(:procedure, :published) }
    let(:procedure_2) { create(:procedure, :published) }

    let(:dossier_0) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure_1, user: user_1) }
    let(:dossier_0b) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure_1, user: user_2) }

    let(:etablissement_1) { create(:etablissement, entreprise_raison_sociale: 'OCTO Academy', siret: '41636169600051') }
    let(:dossier_1) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, user: user_1, etablissement: etablissement_1) }

    let(:etablissement_2) { create(:etablissement, entreprise_raison_sociale: 'Plop octo', siret: '41816602300012') }
    let(:dossier_2) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, user: user_1, etablissement: etablissement_2) }

    let(:etablissement_3) { create(:etablissement, entreprise_raison_sociale: 'OCTO Technology', siret: '41816609600051') }
    let(:dossier_3) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_2, user: user_1, etablissement: etablissement_3) }

    let(:dossier_archived) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure_1, archived: true, user: user_1) }

    describe 'search is empty' do
      let(:terms) { '' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search by dossier id' do
      context 'when the user owns the dossier' do
        let(:terms) { dossier_0.id.to_s }

        it { expect(subject.map(&:id)).to include(dossier_0.id) }
      end

      context 'when the user does not own the dossier' do
        let(:terms) { dossier_0b.id.to_s }

        it { expect(subject.map(&:id)).not_to include(dossier_0b.id) }
      end
    end

    describe 'search brouillon file' do
      let(:terms) { 'brouillon' }

      it { expect(subject.size).to eq(0) }
    end

    describe 'search on contact email' do
      let(:terms) { 'bidou@clap.fr' }

      it { expect(subject.size).to eq(5) }
    end

    describe 'search on contact name' do
      let(:terms) { 'bidou@clap.fr' }

      it { expect(subject.size).to eq(5) }
    end

    describe 'search on SIRET' do
      context 'when is part of SIRET' do
        let(:terms) { '4181' }

        it { expect(subject.size).to eq(2) }
      end

      context 'when is a complet SIRET' do
        let(:terms) { '41816602300012' }

        it { expect(subject.size).to eq(1) }
      end
    end

    describe 'search on raison social' do
      let(:terms) { 'OCTO' }

      it { expect(subject.size).to eq(3) }
    end

    describe 'search terms surrounded with spurious spaces' do
      let(:terms) { ' OCTO ' }

      it { expect(subject.size).to eq(3) }
    end

    describe 'search on multiple fields' do
      let(:terms) { 'octo plop' }

      it { expect(subject.size).to eq(1) }
    end

    describe 'search with characters disallowed by the tsquery parser' do
      let(:terms) { "'?\\:&!(OCTO) <plop>" }

      it { expect(subject.size).to eq(1) }
    end

    describe 'search with a single forbidden character should not crash postgres' do
      let(:terms) { '? OCTO' }

      it { expect(subject.size).to eq(3) }
    end
  end
end
