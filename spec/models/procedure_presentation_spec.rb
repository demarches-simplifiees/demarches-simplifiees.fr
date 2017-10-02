require 'spec_helper'

describe ProcedurePresentation do
  let (:procedure_presentation_id) { ProcedurePresentation.create(displayed_fields: [
    { "label" => "test1", "table" => "user" }.to_json,
    { "label" => "test2", "table" => "champs" }.to_json]
    ).id }
  let (:procedure_presentation) { ProcedurePresentation.find(procedure_presentation_id) }

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{"label" => "test1", "table" => "user"}, {"label" => "test2", "table" => "champs"}]) }
  end
end
