require 'spec_helper'

describe Dossier do
  let(:user) { create(:user) }

  describe 'database columns' do
    it { is_expected.to have_db_column(:autorisation_donnees) }
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
    it { is_expected.to have_many(:cerfa) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
    it { is_expected.to have_one(:individual) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:invites) }
    it { is_expected.to have_many(:follows) }
    it { is_expected.to have_many(:notifications) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:siren).to(:entreprise) }
    it { is_expected.to delegate_method(:siret).to(:etablissement) }
    it { is_expected.to delegate_method(:types_de_piece_justificative).to(:procedure) }
    it { is_expected.to delegate_method(:types_de_champ).to(:procedure) }
    it { is_expected.to delegate_method(:france_connect_information).to(:user) }
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

    describe '#retrieve_last_piece_justificative_by_type', vcr: {cassette_name: 'models_dossier_retrieve_last_piece_justificative_by_type'} do
      let(:types_de_pj_dossier) { dossier.procedure.types_de_piece_justificative }

      subject { dossier.retrieve_last_piece_justificative_by_type types_de_pj_dossier.first }

      before do
        create :piece_justificative, :rib, dossier: dossier, type_de_piece_justificative: types_de_pj_dossier.first
      end

      it 'returns piece justificative with given type' do
        expect(subject.type).to eq(types_de_pj_dossier.first.id)
      end
    end

    describe '#build_default_champs' do
      context 'when dossier is linked to a procedure with type_de_champ_public and private' do
        let(:dossier) { create(:dossier, user: user) }

        it 'build all champs needed' do
          expect(dossier.champs.count).to eq(1)
        end

        it 'build all champs_private needed' do
          expect(dossier.champs_private.count).to eq(1)
        end
      end
    end

    describe '#build_default_individual' do
      context 'when dossier is linked to a procedure with for_individual attr false' do
        let(:dossier) { create(:dossier, user: user) }

        it 'have no object created' do
          expect(dossier.individual).to be_nil
        end
      end

      context 'when dossier is linked to a procedure with for_individual attr true' do
        let(:dossier) { create(:dossier, user: user, procedure: (create :procedure, for_individual: true)) }

        it 'have no object created' do
          expect(dossier.individual).not_to be_nil
        end
      end
    end

    describe '#save' do
      subject { build(:dossier, procedure: procedure, user: user) }
      let!(:procedure) { create(:procedure) }

      context 'when is linked to a procedure' do
        it 'creates default champs' do
          expect(subject).to receive(:build_default_champs)
          subject.save
        end
      end
      context 'when is not linked to a procedure' do
        subject { create(:dossier, procedure: nil, user: user) }

        it 'does not create default champs' do
          expect(subject).not_to receive(:build_default_champs)
          subject.update_attributes(state: 'initiated')
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

          context 'when is follow' do
            let(:action) { 'follow' }

            it { is_expected.to eq 'updated' }
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

            it { is_expected.to eq('updated') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('replied') }
          end

          context 'when is follow' do
            let(:action) { 'follow' }

            it { is_expected.to eq 'replied' }
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

        end
      end

      context 'when dossier is at state received' do
        before do
          dossier.received!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('received') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('received') }
          end

          context 'when he closes the dossier' do
            let(:action) { 'close' }

            it { is_expected.to eq('closed') }
          end
        end
      end

      context 'when dossier is at state refused' do
        before do
          dossier.refused!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('refused') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('refused') }
          end
        end
      end

      context 'when dossier is at state without_continuation' do
        before do
          dossier.without_continuation!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('without_continuation') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('without_continuation') }
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

      let(:gestionnaire) { create(:gestionnaire, administrateurs: [admin]) }
      let(:procedure_admin) { create(:procedure, administrateur: admin) }
      let(:procedure_admin_2) { create(:procedure, administrateur: admin_2) }

      let!(:dossier) { create(:dossier, procedure: procedure_admin, state: 'draft') }
      let!(:dossier2) { create(:dossier, procedure: procedure_admin, state: 'initiated') } #nouveaux
      let!(:dossier3) { create(:dossier, procedure: procedure_admin, state: 'initiated') } #nouveaux
      let!(:dossier4) { create(:dossier, procedure: procedure_admin, state: 'replied') } #en_attente
      let!(:dossier5) { create(:dossier, procedure: procedure_admin, state: 'updated') } #a_traiter
      let!(:dossier6) { create(:dossier, procedure: procedure_admin, state: 'received') } #a_instruire
      let!(:dossier7) { create(:dossier, procedure: procedure_admin, state: 'received') } #a_instruire
      let!(:dossier8) { create(:dossier, procedure: procedure_admin, state: 'closed') } #termine
      let!(:dossier9) { create(:dossier, procedure: procedure_admin, state: 'refused') } #termine
      let!(:dossier10) { create(:dossier, procedure: procedure_admin, state: 'without_continuation') } #termine
      let!(:dossier11) { create(:dossier, procedure: procedure_admin_2, state: 'closed') } #termine
      let!(:dossier12) { create(:dossier, procedure: procedure_admin, state: 'initiated', archived: true) } #a_traiter #archived
      let!(:dossier13) { create(:dossier, procedure: procedure_admin, state: 'replied', archived: true) } #en_attente #archived
      let!(:dossier14) { create(:dossier, procedure: procedure_admin, state: 'closed', archived: true) } #termine #archived

      before do
        create :assign_to, gestionnaire: gestionnaire, procedure: procedure_admin
      end

      describe '#nouveaux' do
        subject { gestionnaire.dossiers.nouveaux }

        it { expect(subject.size).to eq(2) }
      end

      describe '#waiting_for_gestionnaire' do
        subject { gestionnaire.dossiers.waiting_for_gestionnaire }

        it { expect(subject.size).to eq(1) }
      end

      describe '#waiting_for_user' do
        subject { gestionnaire.dossiers.waiting_for_user }

        it { expect(subject.size).to eq(1) }
      end

      describe '#en_instruction' do
        subject { gestionnaire.dossiers.en_instruction }

        it { expect(subject.size).to eq(2) }
        it { expect(subject).to include(dossier6, dossier7) }
      end
    end
  end

  describe '#cerfa_available?' do
    let(:procedure) { create(:procedure, cerfa_flag: cerfa_flag) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    context 'Procedure accepts CERFA' do
      let(:cerfa_flag) { true }
      context 'when cerfa is not uploaded' do
        it { expect(dossier.cerfa_available?).to be_falsey }
      end
      context 'when cerfa is uploaded' do
        let(:dossier) { create :dossier, :with_cerfa_upload, procedure: procedure }
        it { expect(dossier.cerfa_available?).to be_truthy }
      end
    end
    context 'Procedure does not accept CERFA' do
      let(:cerfa_flag) { false }
      it { expect(dossier.cerfa_available?).to be_falsey }
    end
  end

  describe '#convert_specific_hash_values_to_string(hash_to_convert)' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure) }
    let(:dossier_serialized_attributes) { DossierSerializer.new(dossier).attributes }

    subject { dossier.convert_specific_hash_values_to_string(dossier_serialized_attributes) }

    it { expect(dossier_serialized_attributes[:id]).to be_an(Integer) }
    it { expect(dossier_serialized_attributes[:created_at]).to be_a(Time) }
    it { expect(dossier_serialized_attributes[:updated_at]).to be_a(Time) }
    it { expect(dossier_serialized_attributes[:archived]).to be_in([true, false]) }
    it { expect(dossier_serialized_attributes[:mandataire_social]).to be_in([true, false]) }
    it { expect(dossier_serialized_attributes[:state]).to be_a(String) }

    it { expect(subject[:id]).to be_a(String) }
    it { expect(subject[:created_at]).to be_a(Time) }
    it { expect(subject[:updated_at]).to be_a(Time) }
    it { expect(subject[:archived]).to be_a(String) }
    it { expect(subject[:mandataire_social]).to be_a(String) }
    it { expect(subject[:state]).to be_a(String) }
  end

  describe '#export_entreprise_data' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure) }

    subject { dossier.export_entreprise_data }

    it { expect(subject[:etablissement_siret]).to eq('44011762001530') }
    it { expect(subject[:etablissement_siege_social]).to eq('true') }
    it { expect(subject[:etablissement_naf]).to eq('4950Z') }
    it { expect(subject[:etablissement_libelle_naf]).to eq('Transports par conduites') }
    it { expect(subject[:etablissement_adresse]).to eq('GRTGAZ IMMEUBLE BORA 6 RUE RAOUL NORDLING 92270 BOIS COLOMBES') }
    it { expect(subject[:etablissement_numero_voie]).to eq('6') }
    it { expect(subject[:etablissement_type_voie]).to eq('RUE') }
    it { expect(subject[:etablissement_nom_voie]).to eq('RAOUL NORDLING') }
    it { expect(subject[:etablissement_complement_adresse]).to eq('IMMEUBLE BORA') }
    it { expect(subject[:etablissement_code_postal]).to eq('92270') }
    it { expect(subject[:etablissement_localite]).to eq('BOIS COLOMBES') }
    it { expect(subject[:etablissement_code_insee_localite]).to eq('92009') }
    it { expect(subject[:entreprise_siren]).to eq('440117620') }
    it { expect(subject[:entreprise_capital_social]).to eq('537100000') }
    it { expect(subject[:entreprise_numero_tva_intracommunautaire]).to eq('FR27440117620') }
    it { expect(subject[:entreprise_forme_juridique]).to eq("SA à conseil d'administration (s.a.i.)") }
    it { expect(subject[:entreprise_forme_juridique_code]).to eq('5599') }
    it { expect(subject[:entreprise_nom_commercial]).to eq('GRTGAZ') }
    it { expect(subject[:entreprise_raison_sociale]).to eq('GRTGAZ') }
    it { expect(subject[:entreprise_siret_siege_social]).to eq('44011762001530') }
    it { expect(subject[:entreprise_code_effectif_entreprise]).to eq('51') }
    it { expect(subject[:entreprise_date_creation]).to eq('Thu, 28 Jan 2016 10:16:29 UTC +00:0') }
    it { expect(subject[:entreprise_nom]).to be_nil }
    it { expect(subject[:entreprise_prenom]).to be_nil }

    it { expect(subject.count).to eq(EntrepriseSerializer.new(Entreprise.new).as_json.count + EtablissementSerializer.new(Etablissement.new).as_json.count) }
  end

  context 'when dossier is followed' do
    let(:procedure) { create(:procedure, :with_type_de_champ) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:follow) { create(:follow, gestionnaire: gestionnaire) }
    let(:date1) { 1.day.ago }
    let(:date2) { 1.hour.ago }
    let(:date3) { 1.minute.ago }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure, follows: [follow], initiated_at: date1, received_at: date2, processed_at: date3) }

    describe '#export_headers' do
      subject { dossier.export_headers }

      it { expect(subject).to include(:description) }
      it { expect(subject).to include(:individual_gender) }
      it { expect(subject).to include(:individual_nom) }
      it { expect(subject).to include(:individual_prenom) }
      it { expect(subject).to include(:individual_birthdate) }
      it { expect(subject.count).to eq(DossierTableExportSerializer.new(dossier).attributes.count + dossier.procedure.types_de_champ.count + dossier.export_entreprise_data.count) }
    end

    describe '#data_with_champs' do
      subject { dossier.data_with_champs }

      it { expect(subject[0]).to be_a_kind_of(Integer) }
      it { expect(subject[1]).to be_a_kind_of(Time) }
      it { expect(subject[2]).to be_a_kind_of(Time) }
      it { expect(subject[3]).to be_in([true, false]) }
      it { expect(subject[4]).to be_in([true, false]) }
      it { expect(subject[5]).to eq("draft") }
      it { expect(subject[6]).to eq(date1) }
      it { expect(subject[7]).to eq(date2) }
      it { expect(subject[8]).to eq(date3) }
      it { expect(subject[9]).to be_a_kind_of(String) }
      it { expect(subject[10]).to be_nil }
      it { expect(subject[11]).to be_nil }
      it { expect(subject[12]).to be_nil }
      it { expect(subject[13]).to be_nil }
      it { expect(subject.count).to eq(DossierTableExportSerializer.new(dossier).attributes.count + dossier.procedure.types_de_champ.count + dossier.export_entreprise_data.count) }

      context 'dossier for individual' do
        let(:dossier_with_individual) { create(:dossier, :for_individual, user: user, procedure: procedure) }

        subject { dossier_with_individual.data_with_champs }

        it { expect(subject[10]).to eq(dossier_with_individual.individual.gender) }
        it { expect(subject[11]).to eq(dossier_with_individual.individual.prenom) }
        it { expect(subject[12]).to eq(dossier_with_individual.individual.nom) }
        it { expect(subject[13]).to eq(dossier_with_individual.individual.birthdate) }
      end
    end

    describe "#full_data_string" do
      let(:expected_string) {
        [
          dossier.id.to_s,
          dossier.created_at,
          dossier.updated_at,
          "false",
          "false",
          "draft",
          dossier.initiated_at,
          dossier.received_at,
          dossier.processed_at,
          gestionnaire.email,
          nil,
          nil,
          nil,
          nil,
          nil,
          "44011762001530",
          "true",
          "4950Z",
          "Transports par conduites",
          "GRTGAZ IMMEUBLE BORA 6 RUE RAOUL NORDLING 92270 BOIS COLOMBES",
          "6",
          "RUE",
          "RAOUL NORDLING",
          "IMMEUBLE BORA",
          "92270",
          "BOIS COLOMBES",
          "92009",
          "440117620",
          "537100000",
          "FR27440117620",
          "SA à conseil d'administration (s.a.i.)",
          "5599",
          "GRTGAZ",
          "GRTGAZ",
          "44011762001530",
          "51",
          dossier.entreprise.date_creation,
          nil,
          nil
        ]
      }

      subject { dossier }

      it { expect(dossier.full_data_strings_array).to eq(expected_string)}
    end
  end

  describe '#reset!' do
    let!(:dossier) { create :dossier, :with_entreprise, autorisation_donnees: true }
    let!(:rna_information) { create :rna_information, entreprise: dossier.entreprise }
    let!(:exercice) { create :exercice, etablissement: dossier.etablissement }

    subject { dossier.reset! }

    it { expect(dossier.entreprise).not_to be_nil }
    it { expect(dossier.etablissement).not_to be_nil }
    it { expect(dossier.etablissement.exercices).not_to be_empty }
    it { expect(dossier.etablissement.exercices.size).to eq 1 }
    it { expect(dossier.entreprise.rna_information).not_to be_nil }
    it { expect(dossier.autorisation_donnees).to be_truthy }

    it { expect { subject }.to change(RNAInformation, :count).by(-1) }
    it { expect { subject }.to change(Exercice, :count).by(-1) }

    it { expect { subject }.to change(Entreprise, :count).by(-1) }
    it { expect { subject }.to change(Etablissement, :count).by(-1) }

    context 'when method reset! is call' do
      before do
        subject
        dossier.reload
      end

      it { expect(dossier.entreprise).to be_nil }
      it { expect(dossier.etablissement).to be_nil }
      it { expect(dossier.autorisation_donnees).to be_falsey }
    end
  end

  describe '#ordered_champs' do
    let!(:procedure_1) { create :procedure }
    let!(:procedure_2) { create :procedure }

    let(:dossier_1) { Dossier.new(id: 0, procedure: procedure_1) }
    let(:dossier_2) { Dossier.new(id: 0, procedure: procedure_2) }

    before do
      create :type_de_champ_public, libelle: 'type_1_1', order_place: 1, procedure: dossier_1.procedure
      create :type_de_champ_public, libelle: 'type_1_2', order_place: 2, procedure: dossier_1.procedure

      create :type_de_champ_public, libelle: 'type_2_1', order_place: 1, procedure: dossier_2.procedure
      create :type_de_champ_public, libelle: 'type_2_2', order_place: 2, procedure: dossier_2.procedure
      create :type_de_champ_public, libelle: 'type_2_3', order_place: 3, procedure: dossier_2.procedure

      dossier_1.build_default_champs
      dossier_2.build_default_champs
    end

    subject { dossier.ordered_champs }

    it { expect(ChampPublic.where(dossier_id: 0).size).to eq 5 }

    describe 'for dossier 1' do
      let(:dossier) { dossier_1 }

      it { expect(subject.size).to eq 2 }
      it { expect(subject.first.type_de_champ.libelle).to eq 'type_1_1' }
      it { expect(subject.last.type_de_champ.libelle).to eq 'type_1_2' }
    end

    describe 'for dossier 2' do
      let(:dossier) { dossier_2 }

      it { expect(subject.size).to eq 3 }

      it { expect(subject.first.type_de_champ.libelle).to eq 'type_2_1' }
      it { expect(subject.second.type_de_champ.libelle).to eq 'type_2_2' }
      it { expect(subject.last.type_de_champ.libelle).to eq 'type_2_3' }
    end

  end

  describe '#ordered_champs_private' do
    let!(:procedure_1) { create :procedure }
    let!(:procedure_2) { create :procedure }

    let(:dossier_1) { Dossier.new(id: 0, procedure: procedure_1) }
    let(:dossier_2) { Dossier.new(id: 0, procedure: procedure_2) }

    before do
      create :type_de_champ_private, libelle: 'type_1_1', order_place: 1, procedure: dossier_1.procedure
      create :type_de_champ_private, libelle: 'type_1_2', order_place: 2, procedure: dossier_1.procedure

      create :type_de_champ_private, libelle: 'type_2_1', order_place: 1, procedure: dossier_2.procedure
      create :type_de_champ_private, libelle: 'type_2_2', order_place: 2, procedure: dossier_2.procedure
      create :type_de_champ_private, libelle: 'type_2_3', order_place: 3, procedure: dossier_2.procedure

      dossier_1.build_default_champs
      dossier_2.build_default_champs
    end

    subject { dossier.ordered_champs_private }

    it { expect(ChampPrivate.where(dossier_id: 0).size).to eq 5 }

    describe 'for dossier 1' do
      let(:dossier) { dossier_1 }

      it { expect(subject.size).to eq 2 }
      it { expect(subject.first.type_de_champ.libelle).to eq 'type_1_1' }
      it { expect(subject.last.type_de_champ.libelle).to eq 'type_1_2' }
    end

    describe 'for dossier 2' do
      let(:dossier) { dossier_2 }

      it { expect(subject.size).to eq 3 }

      it { expect(subject.first.type_de_champ.libelle).to eq 'type_2_1' }
      it { expect(subject.second.type_de_champ.libelle).to eq 'type_2_2' }
      it { expect(subject.last.type_de_champ.libelle).to eq 'type_2_3' }
    end
  end

  describe '#total_follow' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }
    let(:dossier2) { create(:dossier, :with_entreprise, user: user) }

    subject { dossier.total_follow }

    context 'when no body follow dossier' do
      it { expect(subject).to eq 0 }
    end

    context 'when 2 people follow dossier' do
      before do
        create :follow, dossier_id: dossier.id, gestionnaire_id: (create :gestionnaire).id
        create :follow, dossier_id: dossier.id, gestionnaire_id: (create :gestionnaire).id

        create :follow, dossier_id: dossier2.id, gestionnaire_id: (create :gestionnaire).id
        create :follow, dossier_id: dossier2.id, gestionnaire_id: (create :gestionnaire).id
      end

      it { expect(subject).to eq 2 }
    end
  end

  describe '#invite_by_user?' do
    let(:dossier) { create :dossier }
    let(:invite_user) { create :user, email: user_invite_email }
    let(:invite_gestionnaire) { create :user, email: gestionnaire_invite_email }
    let(:user_invite_email) { 'plup@plop.com' }
    let(:gestionnaire_invite_email) { 'plap@plip.com' }

    before do
      create :invite, dossier: dossier, user: invite_user, email: invite_user.email, type: 'InviteUser'
      create :invite, dossier: dossier, user: invite_gestionnaire, email: invite_gestionnaire.email, type: 'InviteGestionnaire'
    end

    subject { dossier.invite_by_user? email }

    context 'when email is present on invite list' do
      let(:email) { user_invite_email }

      it { is_expected.to be_truthy }
    end

    context 'when email is present on invite list' do
      let(:email) { gestionnaire_invite_email }

      it { is_expected.to be_falsey }
    end
  end

  describe "#text_summary" do
    let(:procedure) { create(:procedure, libelle: "Procédure", organisation: "Organisme") }

    context 'when the dossier has been initiated' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'initiated', initiated_at: "31/12/2010".to_date }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier déposé le 31/12/2010 sur la procédure Procédure gérée par l'organisme Organisme") }
    end

    context 'when the dossier has not been initiated' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'draft' }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier en brouillon répondant à la procédure Procédure gérée par l'organisme Organisme") }
    end
  end

  describe '#update_state_dates' do
    let(:state) { 'draft' }
    let(:dossier) { create(:dossier, state: state) }
    let(:beginning_of_day) { Time.now.beginning_of_day }

    before do
      Timecop.freeze(beginning_of_day)
    end

    context 'when dossier is initiated' do
      before do
        dossier.initiated!
        dossier.reload
      end

      it { expect(dossier.state).to eq('initiated') }
      it { expect(dossier.initiated_at).to eq(beginning_of_day) }

      it 'should keep first initiated_at date' do
        Timecop.return
        dossier.received!
        dossier.initiated!

        expect(dossier.initiated_at).to eq(beginning_of_day)
      end
    end

    context 'when dossier is received' do
      let(:state) { 'initiated' }

      before do
        dossier.received!
        dossier.reload
      end

      it { expect(dossier.state).to eq('received') }
      it { expect(dossier.received_at).to eq(beginning_of_day) }

      it 'should keep first received_at date if dossier is set to initiated again' do
        Timecop.return
        dossier.initiated!
        dossier.received!

        expect(dossier.received_at).to eq(beginning_of_day)
      end
    end

    shared_examples 'dossier is processed' do |new_state|
      before do
        dossier.update(state: new_state)
        dossier.reload
      end

      it { expect(dossier.state).to eq(new_state) }
      it { expect(dossier.processed_at).to eq(beginning_of_day) }
    end

    context 'when dossier is closed' do
      let(:state) { 'received' }

      it_behaves_like 'dossier is processed', 'closed'
    end

    context 'when dossier is refused' do
      let(:state) { 'received' }

      it_behaves_like 'dossier is processed', 'refused'
    end

    context 'when dossier is without_continuation' do
      let(:state) { 'received' }

      it_behaves_like 'dossier is processed', 'without_continuation'
    end

  end

  describe '.downloadable' do
    let(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: :draft) }
    let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: :initiated) }
    let!(:dossier3) { create(:dossier, :with_entreprise, procedure: procedure, state: :received) }
    let!(:dossier4) { create(:dossier, :with_entreprise, procedure: procedure, state: :received, archived: true) }

    subject { procedure.dossiers.downloadable }

    it { is_expected.not_to include(dossier)}
    it { is_expected.to include(dossier2)}
    it { is_expected.to include(dossier3)}
    it { is_expected.to include(dossier4)}
  end
end
