# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcedureLinter do
  let(:procedure) { create(:procedure, :draft) }
  let(:revision) { procedure.draft_revision }

  it "flags uppercase labels" do
    revision.add_type_de_champ(type_champ: "text", libelle: "TITRE EN MAJUSCULES")
    linter = described_class.new(procedure, revision)
    rule = linter.details[:uppercase_in_libelles?]
    expect(rule.pass).to be(false)
    expect(rule.details.map(&:last)).to include("TITRE EN MAJUSCULES")
  end

  it "flags too long labels" do
    revision.add_type_de_champ(type_champ: "text", libelle: "x" * 120)
    linter = described_class.new(procedure, revision)
    rule = linter.details[:too_long_libelle?]
    expect(rule.pass).to be(false)
  end
end

