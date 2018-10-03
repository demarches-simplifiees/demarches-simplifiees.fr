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
end
