# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instructeurs::SelectProcedureDropDownListComponent, type: :component do
  subject do
    render_inline(described_class.new(procedures:))
  end

  let(:procedures) {
    [
      create(:procedure, libelle: "Procedure importante", id: 1001),
      create(:procedure, libelle: "Procedure facile", id: 1002),
      create(:procedure, libelle: "Procedure terminée", id: 1003),
      create(:procedure, libelle: "Procedure terminée 2", id: 1004),
      create(:procedure, libelle: "Procedure terminée 3", id: 1005)
    ]
  }

  it "renders the label" do
    expect(subject).to have_text("Accès direct")
  end

  let(:react_component) { page.find('react-component') }
  let(:react_props_items) { JSON.parse(react_component['props']) }

  it "renders the procedures" do
    subject
    expect(react_props_items["items"]).to eq([
      ["n°1001 - Procedure importante", 1001],
      ["n°1002 - Procedure facile", 1002],
      ["n°1003 - Procedure terminée", 1003],
      ["n°1004 - Procedure terminée 2", 1004],
      ["n°1005 - Procedure terminée 3", 1005]
    ])
  end
end
