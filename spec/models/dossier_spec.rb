require 'spec_helper'

describe Dossier do
  let(:user) { create(:user) }
  describe 'database columns' do
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:autorisation_donnees) }
    it { is_expected.to have_db_column(:nom_projet) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
    it { is_expected.to have_db_column(:state) }
    it { is_expected.to have_db_column(:procedure_id) }
    it { is_expected.to have_db_column(:user_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:procedure) }
    it { is_expected.to have_many(:pieces_justificatives) }
    it { is_expected.to have_many(:champs) }
    it { is_expected.to have_many(:commentaires) }
    it { is_expected.to have_many(:quartier_prioritaires) }
    it { is_expected.to have_many(:cadastres) }
    it { is_expected.to have_one(:cerfa) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:invites) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:siren).to(:entreprise) }
    it { is_expected.to delegate_method(:siret).to(:etablissement) }
    it { is_expected.to delegate_method(:types_de_piece_justificative).to(:procedure) }
    it { is_expected.to delegate_method(:types_de_champ).to(:procedure) }
  end

  describe 'validation' do
    context 'nom_projet' do
      it { is_expected.to allow_value(nil).for(:nom_projet) }
      it { is_expected.not_to allow_value('').for(:nom_projet) }
      it { is_expected.to allow_value('mon super projet').for(:nom_projet) }
    end
    context 'description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('ma superbe description').for(:description) }
    end
  end

  describe 'methods' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }

    let(:entreprise) { dossier.entreprise }
    let(:etablissement) { dossier.etablissement }

    subject { dossier }

    describe '#types_de_piece_justificative' do
      subject { dossier.types_de_piece_justificative }
      it 'returns list of required piece justificative' do
        expect(subject.size).to eq(2)
        expect(subject).to include(TypeDePieceJustificative.find(TypeDePieceJustificative.first.id))
      end
    end

    describe 'creation' do
      describe 'Procedure accepts cerfa upload' do
        let(:procedure) { create(:procedure, cerfa_flag: true) }
        let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, user: user) }
        it 'create default cerfa' do
          expect { subject.to change(Cerfa.count).by(1) }
          expect { subject.cerfa_available.to be_truthy }
        end

        it 'link cerfa to dossier' do
          expect { subject.cerfa.to eq(Cerfa.last) }
        end
      end

      describe 'Procedure does not accept cerfa upload' do
        let(:procedure) { create(:procedure, cerfa_flag: false) }
        let(:dossier) { create(:dossier, :with_entreprise, user: user) }
        it 'default cerfa is not created' do
          expect { subject.to change(Cerfa.count).by(0) }
          expect { subject.cerfa.to eq(nil) }
          expect { subject.cerfa_available.to be_falsey }
        end
      end
    end

    describe '#retrieve_piece_justificative_by_type' do
      let(:all_dossier_pj_id) { dossier.procedure.types_de_piece_justificative }
      subject { dossier.retrieve_piece_justificative_by_type all_dossier_pj_id.first }
      before do
        dossier.build_default_pieces_justificatives
      end

      it 'returns piece justificative with given type' do
        expect(subject.type).to eq(all_dossier_pj_id.first.id)
      end
    end

    describe '#build_default_pieces_justificatives' do
      context 'when dossier is linked to a procedure' do
        let(:dossier) { create(:dossier, user: user) }
        it 'build all pieces justificatives needed' do
          expect(dossier.pieces_justificatives.count).to eq(2)
        end
      end
    end

    describe '#build_default_champs' do
      context 'when dossier is linked to a procedure' do
        let(:dossier) { create(:dossier, user: user) }

        it 'build all champs needed' do
          expect(dossier.champs.count).to eq(1)
        end
      end
    end

    describe '#save' do
      subject { build(:dossier, procedure: procedure, user: user) }
      let!(:procedure) { create(:procedure) }
      context 'when is linked to a procedure' do
        it 'creates default pieces justificatives' do
          expect(subject).to receive(:build_default_pieces_justificatives)
          subject.save
        end

        it 'creates default champs' do
          expect(subject).to receive(:build_default_champs)
          subject.save
        end
      end
      context 'when is not linked to a procedure' do
        subject { create(:dossier, procedure: procedure, user: user) }
        it 'does not create default pieces justificatives' do
          expect(subject).not_to receive(:build_default_pieces_justificatives)
          subject.update_attributes(description: 'plop')
        end

        it 'does not create default champs' do
          expect(subject).not_to receive(:build_default_champs)
          subject.update_attributes(description: 'plop')
        end
      end
    end

    describe '#next_step' do
      let(:dossier) { create(:dossier) }
      let(:role) { 'user' }
      let(:action) { 'initiate' }

      subject { dossier.next_step! role, action }

      context 'when action is not valid' do
        let(:action) { 'test' }
        it { expect { subject }.to raise_error('action is not valid') }
      end

      context 'when role is not valid' do
        let(:role) { 'test' }
        it { expect { subject }.to raise_error('role is not valid') }
      end

      context 'when dossier is at state draft' do
        before do
          dossier.draft!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he updates dossier informations' do
            let(:action) { 'update' }

            it { is_expected.to eq('draft') }
          end

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('draft') }
          end

          context 'when he initiate a dossier' do
            let(:action) { 'initiate' }

            it { is_expected.to eq('initiated') }
          end
        end
      end

      context 'when dossier is at state initiated' do
        before do
          dossier.initiated!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is update dossier informations' do
            let(:action) { 'update' }

            it { is_expected.to eq('initiated') }
          end

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('initiated') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('replied') }
          end

          context 'when is validated the dossier' do
            let(:action) { 'valid' }

            it { is_expected.to eq('validated') }
          end
        end
      end

      context 'when dossier is at state replied' do
        before do
          dossier.replied!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('updated') }
          end

          context 'when is updated dossier informations' do
            let(:action) { 'update' }

            it {

              is_expected.to eq('updated')
            }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('replied') }
          end

          context 'when is validated the dossier' do
            let(:action) { 'valid' }

            it { is_expected.to eq('validated') }
          end
        end
      end

      context 'when dossier is at state updated' do
        before do
          dossier.updated!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('updated') }
          end

          context 'when is updated dossier informations' do
            let(:action) { 'update' }

            it { is_expected.to eq('updated') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('replied') }
          end

          context 'when is validated the dossier' do
            let(:action) { 'valid' }

            it { is_expected.to eq('validated') }
          end
        end
      end

      context 'when dossier is at state validated' do
        before do
          dossier.validated!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }
            it { is_expected.to eq('validated') }
          end

          context 'when is submitted the dossier' do
            let(:action) { 'submit' }

            it { is_expected.to eq('submitted') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('validated') }
          end
        end
      end

      context 'when dossier is at state submitted' do
        before do
          dossier.submitted!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('submitted') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('submitted') }
          end

          context 'when is closed the dossier' do
            let(:action) { 'close' }

            it { is_expected.to eq('closed') }
          end
        end
      end

      context 'when dossier is at state closed' do
        before do
          dossier.closed!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('closed') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('closed') }
          end
        end
      end
    end

    describe 'gestionnaire backoffice methods' do
      let(:admin) { create(:administrateur) }
      let(:admin_2) { create(:administrateur) }

      let(:gestionnaire) { create(:gestionnaire, administrateur: admin) }
      let(:procedure_admin) { create(:procedure, administrateur: admin) }
      let(:procedure_admin_2) { create(:procedure, administrateur: admin_2) }

      let!(:dossier1) { create(:dossier,  procedure: procedure_admin, state: 'draft') }
      let!(:dossier2) { create(:dossier,  procedure: procedure_admin, state: 'initiated') } #a_traiter
      let!(:dossier3) { create(:dossier,  procedure: procedure_admin, state: 'initiated') } #a_traiter
      let!(:dossier4) { create(:dossier,  procedure: procedure_admin, state: 'replied') } #en_attente
      let!(:dossier5) { create(:dossier,  procedure: procedure_admin, state: 'updated') } #a_traiter
      let!(:dossier6) { create(:dossier,  procedure: procedure_admin_2, state: 'validated') } #en_attente
      let!(:dossier7) { create(:dossier,  procedure: procedure_admin_2, state: 'submitted') } #a_traiter
      let!(:dossier8) { create(:dossier,  procedure: procedure_admin_2, state: 'closed') } #termine
      let!(:dossier9) { create(:dossier,  procedure: procedure_admin, state: 'closed') } #termine
      let!(:dossier10) { create(:dossier,  procedure: procedure_admin, state: 'initiated', archived: true) } #a_traiter #archived
      let!(:dossier11) { create(:dossier,  procedure: procedure_admin, state: 'replied', archived: true) } #en_attente #archived
      let!(:dossier12) { create(:dossier,  procedure: procedure_admin, state: 'closed', archived: true) } #termine #archived

      describe '#waiting_for_gestionnaire' do
        subject { gestionnaire.dossiers.waiting_for_gestionnaire }

        it { expect(subject.size).to eq(3) }
      end

      describe '#waiting_for_user' do
        subject { gestionnaire.dossiers.waiting_for_user }

        it { expect(subject.size).to eq(1) }
      end

      describe '#termine' do
        subject { gestionnaire.dossiers.termine }

        it { expect(subject.size).to eq(1) }
      end
    end

    describe '.search' do
      subject { liste_dossiers }

      let(:liste_dossiers) { described_class.search(gestionnaire_1, terms)[0] }
      let(:dossier) { described_class.search(gestionnaire_1, terms)[1] }

      let(:administrateur_1) { create(:administrateur) }
      let(:administrateur_2) { create(:administrateur) }

      let(:gestionnaire_1) { create(:gestionnaire, administrateur: administrateur_1) }
      let(:gestionnaire_2) { create(:gestionnaire, administrateur: administrateur_2) }

      let(:procedure_1) { create(:procedure, administrateur: administrateur_1) }
      let(:procedure_2) { create(:procedure, administrateur: administrateur_2) }

      let!(:dossier_0) { create(:dossier, nom_projet: 'je suis un brouillon', state: 'draft', procedure: procedure_1, user: create(:user, email: 'brouillon@clap.fr')) }
      let!(:dossier_1) { create(:dossier, nom_projet: 'Projet de test', state: 'initiated', procedure: procedure_1, user: create(:user, email: 'contact@test.com')) }
      let!(:dossier_2) { create(:dossier, nom_projet: 'Lili et Marcel', state: 'initiated', procedure: procedure_1, user: create(:user, email: 'plop@gmail.com')) }
      let!(:dossier_3) { create(:dossier, nom_projet: 'Construction projet marcel', state: 'initiated', procedure: procedure_2, user: create(:user, email: 'peace@clap.fr')) }
      let!(:dossier_archived) { create(:dossier, nom_projet: 'je suis un Marcel archivé', state: 'initiated', procedure: procedure_1, archived: true, user: create(:user, email: 'brouillonArchived@clap.fr')) }

      let!(:etablissement_1) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'OCTO Academy', dossier: dossier_1), dossier: dossier_1, siret: '41636169600051') }
      let!(:etablissement_2) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'Plop octo', dossier: dossier_2), dossier: dossier_2, siret: '41816602300012') }
      let!(:etablissement_3) { create(:etablissement, entreprise: create(:entreprise, raison_sociale: 'OCTO Technology', dossier: dossier_3), dossier: dossier_3, siret: '41816609600051') }

      describe 'search is empty' do
        let(:terms) { '' }

        it { expect(subject.size).to eq(0) }
      end

      describe 'search draft file' do
        let(:terms) { 'brouillon' }

        it { expect(subject.size).to eq(0) }
      end

      describe 'search on file title' do
        let(:terms) { 'Marcel' }

        it { expect(subject.size).to eq(1) }
      end

      describe 'search on contact email' do
        let(:terms) { 'clap' }

        it { expect(subject.size).to eq(0) }
      end

      describe 'search on ID dossier' do
        let(:terms) { "#{dossier_2.id}" }

        it { expect(dossier.id).to eq(dossier_2.id) }
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
        let(:terms) { 'octo test' }

        it { expect(subject.size).to eq(1) }
      end
    end
  end

  describe '#cerfa_available?' do
    let(:procedure) { create(:procedure, cerfa_flag: cerfa_flag)  }
    let(:dossier) { create(:dossier, procedure: procedure)}
    context 'Procedure accepts CERFA' do
      let(:cerfa_flag) { true }
      context 'when cerfa is not uploaded' do
        it { expect(dossier.cerfa_available?).to be_falsey }
      end
      context 'when cerfa is uploaded' do
        let(:dossier_with_cerfa) { create(:dossier, procedure: procedure) }
        before do
          allow_any_instance_of(Cerfa).to receive(:empty?).and_return(false)
        end
        it { expect(dossier_with_cerfa.cerfa_available?).to be_truthy }
      end
    end
    context 'Procedure does not accept CERFA' do
      let(:cerfa_flag) { false }
      it { expect(dossier.cerfa_available?).to be_falsey }
    end
  end

  describe '#as_csv?' do
    let(:procedure) { create(:procedure)  }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure) }
    subject { dossier.as_csv }

    it { expect(subject[:nom_projet]).to eq("Demande de subvention dans le cadre d'accompagnement d'enfant à l'étranger") }
    it { expect(subject[:description]).to eq("Ma super description") }
    it { expect(subject[:archived]).to be_falsey }
    it { expect(subject['etablissement.siret']).to eq('44011762001530') }
    it { expect(subject['etablissement.siege_social']).to be_truthy }
    it { expect(subject['etablissement.naf']).to eq('4950Z') }
    it { expect(subject['etablissement.libelle_naf']).to eq('Transports par conduites') }
    it { expect(subject['etablissement.adresse']).to eq("GRTGAZ\r IMMEUBLE BORA\r 6 RUE RAOUL NORDLING\r 92270 BOIS COLOMBES\r") }
    it { expect(subject['etablissement.numero_voie']).to eq('6') }
    it { expect(subject['etablissement.type_voie']).to eq('RUE') }
    it { expect(subject['etablissement.nom_voie']).to eq('RAOUL NORDLING') }
    it { expect(subject['etablissement.complement_adresse']).to eq('IMMEUBLE BORA') }
    it { expect(subject['etablissement.code_postal']).to eq('92270') }
    it { expect(subject['etablissement.localite']).to eq('BOIS COLOMBES') }
    it { expect(subject['etablissement.code_insee_localite']).to eq('92009') }
    it { expect(subject['entreprise.siren']).to eq('440117620') }
    it { expect(subject['entreprise.capital_social']).to eq(537100000) }
    it { expect(subject['entreprise.numero_tva_intracommunautaire']).to eq('FR27440117620') }
    it { expect(subject['entreprise.forme_juridique']).to eq("SA à conseil d'administration (s.a.i.)") }
    it { expect(subject['entreprise.forme_juridique_code']).to eq('5599') }
    it { expect(subject['entreprise.nom_commercial']).to eq('GRTGAZ') }
    it { expect(subject['entreprise.raison_sociale']).to eq('GRTGAZ') }
    it { expect(subject['entreprise.siret_siege_social']).to eq('44011762001530') }
    it { expect(subject['entreprise.code_effectif_entreprise']).to eq('51') }
    it { expect(subject['entreprise.date_creation']).to eq('Thu, 28 Jan 2016 10:16:29 UTC +00:0') }
    it { expect(subject['entreprise.nom']).to be_nil }
    it { expect(subject['entreprise.prenom']).to be_nil }
  end

end
