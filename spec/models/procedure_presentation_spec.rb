require 'spec_helper'

describe ProcedurePresentation do
  let(:assign_to) { create(:assign_to, procedure: create(:procedure, :with_type_de_champ)) }
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
end
