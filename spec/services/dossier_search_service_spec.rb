describe DossierSearchService do
  describe '#matching_dossiers' do
    subject { liste_dossiers }

    let(:liste_dossiers) do
      described_class.matching_dossiers(instructeur_1.dossiers, terms)
    end

    let(:administrateur_1) { create(:administrateur) }
    let(:administrateur_2) { create(:administrateur) }

    let(:instructeur_1) { create(:instructeur, administrateurs: [administrateur_1]) }
    let(:instructeur_2) { create(:instructeur, administrateurs: [administrateur_2]) }

    before do
      instructeur_1.assign_to_procedure(procedure_1)
      instructeur_2.assign_to_procedure(procedure_2)

      # create dossier before performing jobs
      # because let!() syntax is executed after "before" callback
      dossier_0
      dossier_1
      dossier_2
      dossier_3
      dossier_archived

      perform_enqueued_jobs(only: DossierIndexSearchTermsJob)
    end

    let(:procedure_1) { create(:procedure, :published, administrateur: administrateur_1) }
    let(:procedure_2) { create(:procedure, :published, administrateur: administrateur_2) }

    let(:dossier_0) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure_1, user: create(:user, email: 'brouillon@clap.fr')) }

    let(:etablissement_1) { create(:etablissement, entreprise_raison_sociale: 'OCTO Academy', siret: '41636169600051') }
    let(:dossier_1) { create(:dossier, :en_construction, procedure: procedure_1, user: create(:user, email: 'contact@test.com'), etablissement: etablissement_1) }

    let(:etablissement_2) { create(:etablissement, entreprise_raison_sociale: 'Plop octo', siret: '41816602300012') }
    let(:dossier_2) { create(:dossier, :en_construction, procedure: procedure_1, user: create(:user, email: 'plop@gmail.com'), etablissement: etablissement_2) }

    let(:etablissement_3) { create(:etablissement, entreprise_raison_sociale: 'OCTO Technology', siret: '41816609600051') }
    let(:dossier_3) { create(:dossier, :en_construction, procedure: procedure_2, user: create(:user, email: 'peace@clap.fr'), etablissement: etablissement_3) }

    let(:dossier_archived) { create(:dossier, :en_construction, procedure: procedure_1, archived: true, user: create(:user, email: 'archived@clap.fr')) }

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
