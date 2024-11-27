# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241127MigrateChampExpressionReguliereToFormattedTask do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: "expression_reguliere" }, { type: "text" }, { type: "formatted" }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }

    describe "#process" do
      let(:champ_regex) { Champ.where(type: ["Champs::ExpressionReguliereChamp"]).first }
      let(:champ_formatted) { Champ.where(type: ["Champs::FormattedChamp"]).first }

      it "update type of regex champ" do
        dossier
        described_class.process(champ_regex)
        expect(champ_regex.type).to eq "Champs::FormattedChamp"
      end

      it "doesn't change type of formatted champ" do
        dossier
        described_class.process(champ_formatted)
        expect(champ_formatted.type).to eq "Champs::FormattedChamp"
      end
    end

    describe '#collection' do
      it "works" do
        dossier # create dossier
        expect(described_class.collection.map(&:type)).to eq(["Champs::ExpressionReguliereChamp", "Champs::FormattedChamp"])
      end
    end
  end
end
