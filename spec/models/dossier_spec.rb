require 'spec_helper'

describe Dossier do
  let(:user) { create(:user) }

  describe "without_followers scope" do
    let!(:dossier) { create(:dossier, :followed, :with_entreprise, user: user) }
    let!(:dossier2) { create(:dossier, :with_entreprise, user: user) }

    it { expect(Dossier.without_followers.to_a).to eq([dossier2]) }
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
          subject.update_attributes(state: 'en_construction')
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

      context 'when dossier is at state brouillon' do
        before do
          dossier.brouillon!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he updates dossier informations' do
            let(:action) { 'update' }

            it { is_expected.to eq('brouillon') }
          end

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('brouillon') }
          end

          context 'when he initiate a dossier' do
            let(:action) { 'initiate' }

            it { is_expected.to eq('en_construction') }
          end
        end
      end

      context 'when dossier is at state en_construction' do
        before do
          dossier.en_construction!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is update dossier informations' do
            let(:action) { 'update' }

            it { is_expected.to eq('en_construction') }
          end

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('en_construction') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('en_construction') }
          end

          context 'when is follow' do
            let(:action) { 'follow' }

            it { is_expected.to eq 'en_construction' }
          end
        end
      end

      context 'when dossier is at state en_instruction' do
        before do
          dossier.en_instruction!
        end

        context 'when user is connected' do
          let(:role) { 'user' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('en_instruction') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when he posts a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('en_instruction') }
          end

          context 'when he closes the dossier' do
            let(:action) { 'close' }

            it { is_expected.to eq('accepte') }
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

      context 'when dossier is at state accepte' do
        before do
          dossier.accepte!
        end

        context 'when user is connect' do
          let(:role) { 'user' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('accepte') }
          end
        end

        context 'when gestionnaire is connect' do
          let(:role) { 'gestionnaire' }

          context 'when is post a comment' do
            let(:action) { 'comment' }

            it { is_expected.to eq('accepte') }
          end
        end
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
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:date1) { 1.day.ago }
    let(:date2) { 1.hour.ago }
    let(:date3) { 1.minute.ago }
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure, en_construction_at: date1, en_instruction_at: date2, processed_at: date3, motivation: "Motivation") }
    let!(:follow) { create(:follow, gestionnaire: gestionnaire, dossier: dossier) }

    describe '#export_headers' do
      subject { dossier.export_headers }

      it { expect(subject).to include(dossier.champs.first.libelle.parameterize.underscore.to_sym) }
      it { expect(subject).to include(:individual_gender) }
      it { expect(subject).to include(:individual_nom) }
      it { expect(subject).to include(:individual_prenom) }
      it { expect(subject).to include(:individual_birthdate) }
      it { expect(subject.count).to eq(DossierTableExportSerializer.new(dossier).attributes.count +
        dossier.procedure.types_de_champ.count +
        dossier.procedure.types_de_champ_private.count +
        dossier.export_entreprise_data.count)
      }
    end

    describe '#to_sorted_values' do
      subject { dossier.to_sorted_values }

      it { expect(subject[0]).to be_a_kind_of(Integer) }
      it { expect(subject[1]).to be_a_kind_of(Time) }
      it { expect(subject[2]).to be_a_kind_of(Time) }
      it { expect(subject[3]).to be_in([true, false]) }
      it { expect(subject[4]).to eq(dossier.user.email) }
      it { expect(subject[5]).to be_in([true, false]) }
      it { expect(subject[6]).to eq("brouillon") }
      it { expect(subject[7]).to eq(date1) }
      it { expect(subject[8]).to eq(date2) }
      it { expect(subject[9]).to eq(date3) }
      it { expect(subject[10]).to be_a_kind_of(String) }
      it { expect(subject[11]).to be_a_kind_of(String) }
      it { expect(subject[12]).to be_nil }
      it { expect(subject[13]).to be_nil }
      it { expect(subject[14]).to be_nil }
      it { expect(subject[15]).to be_nil }
      it { expect(subject[16]).to be_nil }
      it { expect(subject.count).to eq(DossierTableExportSerializer.new(dossier).attributes.count +
        dossier.procedure.types_de_champ.count +
        dossier.procedure.types_de_champ_private.count +
        dossier.export_entreprise_data.count)
      }

      context 'dossier for individual' do
        let(:dossier_with_individual) { create(:dossier, :for_individual, user: user, procedure: procedure) }

        subject { dossier_with_individual.to_sorted_values }

        it { expect(subject[12]).to eq(dossier_with_individual.individual.gender) }
        it { expect(subject[13]).to eq(dossier_with_individual.individual.prenom) }
        it { expect(subject[14]).to eq(dossier_with_individual.individual.nom) }
        it { expect(subject[15]).to eq(dossier_with_individual.individual.birthdate) }
      end
    end

    describe "#full_data_string" do
      let(:expected_string) {
        [
          dossier.id.to_s,
          dossier.created_at,
          dossier.updated_at,
          "false",
          dossier.user.email,
          "false",
          "brouillon",
          dossier.en_construction_at,
          dossier.en_instruction_at,
          dossier.processed_at,
          "Motivation",
          gestionnaire.email,
          nil,
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
    let(:procedure) { create(:procedure) }
    let(:dossier) { Dossier.create(user: create(:user), procedure: procedure) }

    before do
      create(:type_de_champ_public, libelle: 'l1', order_place: 1, procedure: procedure)
      create(:type_de_champ_public, libelle: 'l3', order_place: 3, procedure: procedure)
      create(:type_de_champ_public, libelle: 'l2', order_place: 2, procedure: procedure)
    end

    it { expect(dossier.ordered_champs.pluck(:libelle)).to match(%w(l1 l2 l3)) }
  end

  describe '#ordered_champs_private' do
    let(:procedure) { create :procedure }
    let(:dossier) { Dossier.create(user: create(:user), procedure: procedure) }

    before do
      create :type_de_champ_private, libelle: 'l1', order_place: 1, procedure: procedure
      create :type_de_champ_private, libelle: 'l3', order_place: 3, procedure: procedure
      create :type_de_champ_private, libelle: 'l2', order_place: 2, procedure: procedure
    end

    it { expect(dossier.ordered_champs_private.pluck(:libelle)).to match(%w(l1 l2 l3)) }
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

    context 'when the dossier has been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'en_construction', en_construction_at: "31/12/2010".to_date }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier déposé le 31/12/2010 sur la procédure Procédure gérée par l'organisme Organisme") }
    end

    context 'when the dossier has not been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'brouillon' }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier en brouillon répondant à la procédure Procédure gérée par l'organisme Organisme") }
    end
  end

  describe '#avis_for' do
    let!(:procedure) { create(:procedure, :published) }
    let!(:dossier) { create(:dossier, procedure: procedure, state: :en_construction) }

    let!(:gestionnaire) { create(:gestionnaire, procedures: [procedure]) }
    let!(:expert_1) { create(:gestionnaire) }
    let!(:expert_2) { create(:gestionnaire) }

    context 'when there is a public advice asked from the dossiers gestionnaire' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: gestionnaire, gestionnaire: expert_1, confidentiel: false) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when there is a private advice asked from the dossiers gestionnaire' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: gestionnaire, gestionnaire: expert_1, confidentiel: true) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([]) }
    end

    context 'when there is a public advice asked from one expert to another' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when there is a private advice asked from one expert to another' do
      let!(:avis) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: true) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for(expert_2)).to match([avis]) }
    end

    context 'when they are a lot of advice' do
      let!(:avis_1) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: DateTime.parse('10/01/2010')) }
      let!(:avis_2) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: DateTime.parse('9/01/2010')) }
      let!(:avis_3) { Avis.create(dossier: dossier, claimant: expert_1, gestionnaire: expert_2, confidentiel: false, created_at: DateTime.parse('11/01/2010')) }

      it { expect(dossier.avis_for(gestionnaire)).to match([avis_2, avis_1, avis_3]) }
      it { expect(dossier.avis_for(expert_1)).to match([avis_2, avis_1, avis_3]) }
    end
  end

  describe '#update_state_dates' do
    let(:state) { 'brouillon' }
    let(:dossier) { create(:dossier, state: state) }
    let(:beginning_of_day) { Time.now.beginning_of_day }

    before do
      Timecop.freeze(beginning_of_day)
    end

    context 'when dossier is en_construction' do
      before do
        dossier.en_construction!
        dossier.reload
      end

      it { expect(dossier.state).to eq('en_construction') }
      it { expect(dossier.en_construction_at).to eq(beginning_of_day) }

      it 'should keep first en_construction_at date' do
        Timecop.return
        dossier.en_instruction!
        dossier.en_construction!

        expect(dossier.en_construction_at).to eq(beginning_of_day)
      end
    end

    context 'when dossier is en_instruction' do
      let(:state) { 'en_construction' }

      before do
        dossier.en_instruction!
        dossier.reload
      end

      it { expect(dossier.state).to eq('en_instruction') }
      it { expect(dossier.en_instruction_at).to eq(beginning_of_day) }

      it 'should keep first en_instruction_at date if dossier is set to en_construction again' do
        Timecop.return
        dossier.en_construction!
        dossier.en_instruction!

        expect(dossier.en_instruction_at).to eq(beginning_of_day)
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

    context 'when dossier is accepte' do
      let(:state) { 'en_instruction' }

      it_behaves_like 'dossier is processed', 'accepte'
    end

    context 'when dossier is refused' do
      let(:state) { 'en_instruction' }

      it_behaves_like 'dossier is processed', 'refused'
    end

    context 'when dossier is without_continuation' do
      let(:state) { 'en_instruction' }

      it_behaves_like 'dossier is processed', 'without_continuation'
    end
  end

  describe '.downloadable_sorted' do
    let(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: :brouillon) }
    let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: :en_construction, en_construction_at: DateTime.parse('03/01/2010')) }
    let!(:dossier3) { create(:dossier, :with_entreprise, procedure: procedure, state: :en_instruction, en_construction_at: DateTime.parse('01/01/2010')) }
    let!(:dossier4) { create(:dossier, :with_entreprise, procedure: procedure, state: :en_instruction, archived: true, en_construction_at: DateTime.parse('02/01/2010')) }

    subject { procedure.dossiers.downloadable_sorted }

    it { is_expected.to match([dossier3, dossier4, dossier2])}
  end

  describe "#send_dossier_received" do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure, state: :en_construction) }

    before do
      allow(NotificationMailer).to receive(:send_dossier_received).and_return(double(deliver_later: nil))
    end

    it "sends an email when the dossier becomes en_instruction" do
      dossier.en_instruction!
      expect(NotificationMailer).to have_received(:send_dossier_received).with(dossier.id)
    end

    it "does not an email when the dossier becomes accepte" do
      dossier.accepte!
      expect(NotificationMailer).to_not have_received(:send_dossier_received)
    end
  end

  describe "#send_draft_notification_email" do
    let(:procedure) { create(:procedure) }
    let(:user) { create(:user) }

    before do
      ActionMailer::Base.deliveries.clear
    end

    it "send an email when the dossier is created for the very first time" do
      expect { Dossier.create(procedure: procedure, state: "brouillon", user: user) }.to change(ActionMailer::Base.deliveries, :size).from(0).to(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("Retrouvez votre brouillon pour la démarche : #{procedure.libelle}")
    end

    it "does not send an email when the dossier is created with a non brouillon state" do
      expect { Dossier.create(procedure: procedure, state: "en_construction", user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: "en_instruction", user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: "accepte", user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: "refused", user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { Dossier.create(procedure: procedure, state: "without_continuation", user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
    end
  end

  describe '.build_attestation' do
    let(:attestation_template) { nil }
    let(:procedure) { create(:procedure, attestation_template: attestation_template) }

    before :each do
      dossier.next_step!('gestionnaire', 'close')
      dossier.reload
    end

    context 'when the dossier is in en_instruction state ' do
      let!(:dossier) { create(:dossier, procedure: procedure, state: :en_instruction) }

      context 'when the procedure has no attestation' do
        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure has an unactivated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: false) }

        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure attached has an activated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: true) }

        it { expect(dossier.attestation).not_to be_nil }
      end
    end
  end

  describe ".default_scope" do
    let!(:dossier) { create(:dossier, hidden_at: hidden_at) }

    context "when dossier is not hidden" do
      let(:hidden_at) { nil }

      it { expect(Dossier.count).to eq(1) }
      it { expect(Dossier.all).to include(dossier) }
    end

    context "when dossier is hidden" do
      let(:hidden_at) { 1.day.ago }

      it { expect(Dossier.count).to eq(0) }
    end
  end

  describe "#get_value" do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }

    before do
      FranceConnectInformation.create(france_connect_particulier_id: 123, user: user, gender: 'male')

      @champ_public = dossier.champs.first
      @champ_public.value = "kiwi"
      @champ_public.save

      @champ_private = dossier.champs_private.first
      @champ_private.value = "banane"
      @champ_private.save
    end

    it { expect(dossier.get_value('self', 'created_at')).to eq(dossier.created_at) }
    it { expect(dossier.get_value('user', 'email')).to eq(user.email) }
    it { expect(dossier.get_value('france_connect_information', 'gender')).to eq(user.france_connect_information.gender) }
    it { expect(dossier.get_value('entreprise', 'siren')).to eq(dossier.entreprise.siren) }
    it { expect(dossier.get_value('etablissement', 'siret')).to eq(dossier.etablissement.siret) }
    it { expect(dossier.get_value('type_de_champ', @champ_public.type_de_champ.id.to_s)).to eq(dossier.champs.first.value) }
    it { expect(dossier.get_value('type_de_champ_private', @champ_private.type_de_champ.id.to_s)).to eq(dossier.champs_private.first.value) }
  end

  describe 'updated_at' do
    let!(:dossier) { create(:dossier) }
    let(:modif_date) { DateTime.parse('01/01/2100') }

    before { Timecop.freeze(modif_date) }
    after { Timecop.return }

    subject do
      dossier.reload
      dossier.updated_at
    end

    it { is_expected.not_to eq(modif_date) }

    context 'when a cerfa is modified' do
      before { dossier.cerfa << create(:cerfa) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a piece justificative is modified' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a champ is modified' do
      before { dossier.champs.first.update_attribute('value', 'yop') }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a quartier_prioritaire is modified' do
      before { dossier.quartier_prioritaires << create(:quartier_prioritaire) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a cadastre is modified' do
      before { dossier.cadastres << create(:cadastre) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a commentaire is modified' do
      before { dossier.commentaires << create(:commentaire) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when an avis is modified' do
      before { dossier.avis << create(:avis) }

      it { is_expected.to eq(modif_date) }
    end
  end

  describe '#owner_name' do
    let!(:procedure) { create(:procedure) }
    subject { dossier.owner_name }

    context 'when there is no entreprise or individual' do
      let(:dossier) { create(:dossier, individual: nil, entreprise: nil, procedure: procedure) }

      it { is_expected.to be_nil }
    end

    context 'when there is entreprise' do
      let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }

      it { is_expected.to eq(dossier.entreprise.raison_sociale) }
    end

    context 'when there is an individual' do
      let(:dossier) { create(:dossier, :for_individual, procedure: procedure) }

      it { is_expected.to eq("#{dossier.individual.nom} #{dossier.individual.prenom}") }
    end
  end

  describe 'geometry' do
    let(:dossier) { create(:dossier, json_latlngs: json_latlngs) }
    let(:json_latlngs) { nil }

    subject{ dossier.user_geometry }

    context 'when there are no map' do
      it { is_expected.to eq(nil) }
    end

    context 'when there are 2 polygones' do
      let(:json_latlngs) do
        '[[{"lat": 2.0, "lng": 102.0}, {"lat": 3.0, "lng": 103.0}, {"lat": 2.0, "lng": 102.0}],
          [{"lat": 2.0, "lng": 102.0}, {"lat": 3.0, "lng": 103.0}, {"lat": 2.0, "lng": 102.0}]]'
      end

      let(:expected) do
        {
          "type": "MultiPolygon",
          "coordinates":
          [
            [
              [
                [102.0, 2.0],
                [103.0, 3.0],
                [102.0, 2.0]
              ]
            ],
            [
              [
                [102.0, 2.0],
                [103.0, 3.0],
                [102.0, 2.0]
              ]
            ]
          ]
        }
      end

      subject{ dossier.user_geometry.value }

      it { is_expected.to eq(expected) }
    end
  end
end
