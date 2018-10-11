require 'spec_helper'

describe ProcedurePresentation do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
  let(:assign_to) { create(:assign_to, procedure: procedure) }
  let(:first_type_de_champ_id) { assign_to.procedure.types_de_champ.first.id.to_s }
  let (:procedure_presentation_id) {
    ProcedurePresentation.create(
      assign_to: assign_to,
      displayed_fields: [
        { "label" => "test1", "table" => "user", "column" => "email" },
        { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }
      ],
      sort: { "table" => "user","column" => "email","order" => "asc" },
      filters: { "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] }
    ).id
  }
  let (:procedure_presentation) { ProcedurePresentation.find(procedure_presentation_id) }

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{ "label" => "test1", "table" => "user", "column" => "email" }, { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }]) }
  end

  describe "#sort" do
    it { expect(procedure_presentation.sort).to eq({ "table" => "user","column" => "email","order" => "asc" }) }
  end

  describe "#filters" do
    it { expect(procedure_presentation.filters).to eq({ "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] }) }
  end

  describe 'validation' do
    it { expect(build(:procedure_presentation)).to be_valid }

    context 'of displayed fields' do
      it { expect(build(:procedure_presentation, displayed_fields: [{ "table" => "user", "column" => "reset_password_token", "order" => "asc" }])).to be_invalid }
    end

    context 'of sort' do
      it { expect(build(:procedure_presentation, sort: { "table" => "notifications", "column" => "notifications", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "self", "column" => "id", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "self", "column" => "state", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "user", "column" => "reset_password_token", "order" => "asc" })).to be_invalid }
    end

    context 'of filters' do
      it { expect(build(:procedure_presentation, filters: { "suivis" => [{ "table" => "user", "column" => "reset_password_token", "order" => "asc" }] })).to be_invalid }
    end
  end

  describe "#fields" do
    context 'when the procedure can have a SIRET number' do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, :types_de_champ_count => 4, :types_de_champ_private_count => 4) }
      let(:tdc_1) { procedure.types_de_champ[0] }
      let(:tdc_2) { procedure.types_de_champ[1] }
      let(:tdc_private_1) { procedure.types_de_champ_private[0] }
      let(:tdc_private_2) { procedure.types_de_champ_private[1] }
      let(:expected) {
        [
          { "label" => 'Créé le', "table" => 'self', "column" => 'created_at' },
          { "label" => 'Mis à jour le', "table" => 'self', "column" => 'updated_at' },
          { "label" => 'Demandeur', "table" => 'user', "column" => 'email' },
          { "label" => 'SIREN', "table" => 'etablissement', "column" => 'entreprise_siren' },
          { "label" => 'Forme juridique', "table" => 'etablissement', "column" => 'entreprise_forme_juridique' },
          { "label" => 'Nom commercial', "table" => 'etablissement', "column" => 'entreprise_nom_commercial' },
          { "label" => 'Raison sociale', "table" => 'etablissement', "column" => 'entreprise_raison_sociale' },
          { "label" => 'SIRET siège social', "table" => 'etablissement', "column" => 'entreprise_siret_siege_social' },
          { "label" => 'Date de création', "table" => 'etablissement', "column" => 'entreprise_date_creation' },
          { "label" => 'SIRET', "table" => 'etablissement', "column" => 'siret' },
          { "label" => 'Libellé NAF', "table" => 'etablissement', "column" => 'libelle_naf' },
          { "label" => 'Code postal', "table" => 'etablissement', "column" => 'code_postal' },
          { "label" => tdc_1.libelle, "table" => 'type_de_champ', "column" => tdc_1.id.to_s },
          { "label" => tdc_2.libelle, "table" => 'type_de_champ', "column" => tdc_2.id.to_s },
          { "label" => tdc_private_1.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_1.id.to_s },
          { "label" => tdc_private_2.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_2.id.to_s }
        ]
      }

      before do
        procedure.types_de_champ[2].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:header_section))
        procedure.types_de_champ[3].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:explication))
        procedure.types_de_champ_private[2].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:header_section))
        procedure.types_de_champ_private[3].update_attribute(:type_champ,TypeDeChamp.type_champs.fetch(:explication))
      end

      subject { create(:procedure_presentation, assign_to: create(:assign_to, procedure: procedure)) }

      it { expect(subject.fields).to eq(expected) }
    end

    context 'when the procedure is for individuals' do
      let(:name_field) { { "label" => "Prénom", "table" => "individual", "column" => "prenom" } }
      let(:surname_field) { { "label" => "Nom", "table" => "individual", "column" => "nom" } }
      let(:gender_field) { { "label" => "Civilité", "table" => "individual", "column" => "gender" } }
      let(:procedure) { create(:procedure, :for_individual) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: create(:assign_to, procedure: procedure)) }

      subject { procedure_presentation.fields }

      it { is_expected.to include(name_field, surname_field, gender_field) }
    end
  end

  describe "#fields_for_select" do
    subject { create(:procedure_presentation) }

    before do
      allow(subject).to receive(:fields).and_return([
        {
          "label" => "label1",
          "table" => "table1",
          "column" => "column1"
        },
        {
          "label" => "label2",
          "table" => "table2",
          "column" => "column2"
        }
      ])
    end

    it { expect(subject.fields_for_select).to eq([["label1", "table1/column1"], ["label2", "table2/column2"]]) }
  end

  describe '#get_value' do
    let(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to, displayed_fields: [{ 'table' => table, 'column' => column }]) }

    subject { procedure_presentation.displayed_field_values(dossier).first }

    context 'for self table' do
      let(:table) { 'self' }
      let(:column) { 'updated_at' } # All other columns work the same, no extra test required

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.touch(time: DateTime.new(2018, 9, 25)) }

      it { is_expected.to eq(DateTime.new(2018, 9, 25)) }
    end

    context 'for user table' do
      let(:table) { 'user' }
      let(:column) { 'email' }

      let(:dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'bla@yopmail.com')) }

      it { is_expected.to eq('bla@yopmail.com') }
    end

    context 'for individual table' do
      let(:table) { 'individual' }
      let(:dossier) { create(:dossier, procedure: procedure, individual: create(:individual, nom: 'Martin', prenom: 'Jacques', gender: 'M.')) }

      context 'for prenom column' do
        let(:column) { 'prenom' }

        it { is_expected.to eq('Jacques') }
      end

      context 'for nom column' do
        let(:column) { 'nom' }

        it { is_expected.to eq('Martin') }
      end

      context 'for gender column' do
        let(:column) { 'gender' }

        it { is_expected.to eq('M.') }
      end
    end

    context 'for etablissement table' do
      let(:table) { 'etablissement' }
      let(:column) { 'code_postal' } # All other columns work the same, no extra test required

      let!(:dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }

      it { is_expected.to eq('75008') }
    end

    context 'for type_de_champ table' do
      let(:table) { 'type_de_champ' }
      let(:column) { procedure.types_de_champ.first.id.to_s }

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.champs.first.update(value: 'kale') }

      it { is_expected.to eq('kale') }
    end

    context 'for type_de_champ_private table' do
      let(:table) { 'type_de_champ_private' }
      let(:column) { procedure.types_de_champ_private.first.id.to_s }

      let(:dossier) { create(:dossier, procedure: procedure) }

      before { dossier.champs_private.first.update(value: 'quinoa') }

      it { is_expected.to eq('quinoa') }
    end
  end

  describe '#sorted_ids' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:assign_to) { create(:assign_to, procedure: procedure, gestionnaire: gestionnaire) }
    let(:sort) { { 'table' => table, 'column' => column, 'order' => order } }
    let(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to, sort: sort) }

    subject { procedure_presentation.sorted_ids(procedure.dossiers, gestionnaire) }

    context 'for notifications table' do
      let(:table) { 'notifications' }
      let(:column) { 'notifications' }

      let!(:notified_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:recent_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:older_dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        notified_dossier.champs.first.touch(time: DateTime.new(2018, 9, 20))
        create(:follow, gestionnaire: gestionnaire, dossier: notified_dossier, demande_seen_at: DateTime.new(2018, 9, 10))
        recent_dossier.touch(time: DateTime.new(2018, 9, 25))
        older_dossier.touch(time: DateTime.new(2018, 5, 13))
      end

      context 'in ascending order' do
        let(:order) { 'asc' }

        it { is_expected.to eq([older_dossier, recent_dossier, notified_dossier].map(&:id)) }
      end

      context 'in descending order' do
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end
    end

    context 'for self table' do
      let(:table) { 'self' }
      let(:column) { 'updated_at' } # All other columns work the same, no extra test required
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:recent_dossier) { create(:dossier, procedure: procedure) }
      let(:older_dossier) { create(:dossier, procedure: procedure) }

      before do
        recent_dossier.touch(time: DateTime.new(2018, 9, 25))
        older_dossier.touch(time: DateTime.new(2018, 5, 13))
      end

      it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
    end

    context 'for type_de_champ table' do
      let(:table) { 'type_de_champ' }
      let(:column) { procedure.types_de_champ.first.id.to_s }
      let(:order) { 'desc' } # Asc works the same, no extra test required

      let(:beurre_dossier) { create(:dossier, procedure: procedure) }
      let(:tartine_dossier) { create(:dossier, procedure: procedure) }

      before do
        beurre_dossier.champs.first.update(value: 'beurre')
        tartine_dossier.champs.first.update(value: 'tartine')
      end

      it { is_expected.to eq([tartine_dossier, beurre_dossier].map(&:id)) }
    end

    context 'for type_de_champ_private table' do
      let(:table) { 'type_de_champ_private' }
      let(:column) { procedure.types_de_champ_private.first.id.to_s }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:biere_dossier) { create(:dossier, procedure: procedure) }
      let(:vin_dossier) { create(:dossier, procedure: procedure) }

      before do
        biere_dossier.champs_private.first.update(value: 'biere')
        vin_dossier.champs_private.first.update(value: 'vin')
      end

      it { is_expected.to eq([biere_dossier, vin_dossier].map(&:id)) }
    end

    context 'for other tables' do
      # All other columns and tables work the same so it’s ok to test only one
      let(:table) { 'etablissement' }
      let(:column) { 'code_postal' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:huitieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }
      let!(:vingtieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75020')) }

      it { is_expected.to eq([huitieme_dossier, vingtieme_dossier].map(&:id)) }
    end
  end

  describe '#filtered_ids' do
    let(:procedure_presentation) { create(:procedure_presentation, assign_to: create(:assign_to, procedure: procedure), filters: { "suivis" => filter }) }

    subject { procedure_presentation.filtered_ids(procedure.dossiers, 'suivis') }

    context 'for self table' do
      context 'for created_at column' do
        let!(:kept_dossier) { create(:dossier, procedure: procedure, created_at: DateTime.new(2018, 9, 18, 14, 28)) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, created_at: DateTime.new(2018, 9, 17, 23, 59)) }
        let(:filter) { [{ 'table' => 'self', 'column' => 'created_at', 'value' => '18/9/2018' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_at column' do
        let(:kept_dossier) { create(:dossier, procedure: procedure) }
        let(:discarded_dossier) { create(:dossier, procedure: procedure) }
        let(:filter) { [{ 'table' => 'self', 'column' => 'updated_at', 'value' => '18/9/2018' }] }

        before do
          kept_dossier.touch(time: DateTime.new(2018, 9, 18, 14, 28))
          discarded_dossier.touch(time: DateTime.new(2018, 9, 17, 23, 59))
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end

    context 'for type_de_champ table' do
      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ) { procedure.types_de_champ.first }
      let(:filter) { [{ 'table' => 'type_de_champ', 'column' => type_de_champ.id.to_s, 'value' => 'keep' }] }

      before do
        type_de_champ.champ.create(dossier: kept_dossier, value: 'keep me')
        type_de_champ.champ.create(dossier: discarded_dossier, value: 'discard me')
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'for type_de_champ_private table' do
      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ_private) { procedure.types_de_champ_private.first }
      let(:filter) { [{ 'table' => 'type_de_champ_private', 'column' => type_de_champ_private.id.to_s, 'value' => 'keep' }] }

      before do
        type_de_champ_private.champ.create(dossier: kept_dossier, value: 'keep me')
        type_de_champ_private.champ.create(dossier: discarded_dossier, value: 'discard me')
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'for etablissement table' do
      context 'for entreprise_date_creation column' do
        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: DateTime.new(2018, 6, 21))) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: DateTime.new(2008, 6, 21))) }
        let(:filter) { [{ 'table' => 'etablissement', 'column' => 'entreprise_date_creation', 'value' => '21/6/2018' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for code_postal column' do
        # All columns except entreprise_date_creation work exacly the same, just testing one

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75017')) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '25000')) }
        let(:filter) { [{ 'table' => 'etablissement', 'column' => 'code_postal', 'value' => '75017' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end

    context 'for user table' do
      let!(:kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@keepmail.com')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@discard.com')) }
      let(:filter) { [{ 'table' => 'user', 'column' => 'email', 'value' => 'keepmail' }] }

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'for individual table' do
      let(:procedure) { create(:procedure, :for_individual) }
      let!(:kept_dossier) { create(:dossier, procedure: procedure, individual: create(:individual, gender: 'Mme', prenom: 'Josephine', nom: 'Baker')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, individual: create(:individual, gender: 'M', prenom: 'Jean', nom: 'Tremblay')) }

      context 'for gender column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'gender', 'value' => 'Mme' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for prenom column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'prenom', 'value' => 'Josephine' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for nom column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'nom', 'value' => 'Baker' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end
  end
end
