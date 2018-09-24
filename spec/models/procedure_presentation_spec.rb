require 'spec_helper'

describe ProcedurePresentation do
  let (:procedure_presentation_id) {
    ProcedurePresentation.create(
      displayed_fields: [
        { "label" => "test1", "table" => "user" },
        { "label" => "test2", "table" => "champs" }
      ],
      sort: { "table" => "user","column" => "email","order" => "asc" },
      filters: { "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "table1", "column" => "column1" }] }
    ).id
  }
  let (:procedure_presentation) { ProcedurePresentation.find(procedure_presentation_id) }

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{ "label" => "test1", "table" => "user" }, { "label" => "test2", "table" => "champs" }]) }
  end

  describe "#sort" do
    it { expect(procedure_presentation.sort).to eq({ "table" => "user","column" => "email","order" => "asc" }) }
  end

  describe "#filters" do
    it { expect(procedure_presentation.filters).to eq({ "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "table1", "column" => "column1" }] }) }
  end
end
