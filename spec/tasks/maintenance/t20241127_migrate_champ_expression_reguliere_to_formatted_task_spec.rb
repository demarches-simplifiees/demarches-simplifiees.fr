# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241127MigrateChampExpressionReguliereToFormattedTask do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: "expression_reguliere" }, { type: "text" }, { type: "formatted" }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }

    describe "#process" do
      let(:champ_regex) { Champ.where(type: ["Champs::ExpressionReguliereChamp"]).first }

      it "update type of regex champ" do
        dossier
        champ_id = champ_regex.id
        described_class.process(0)

        expect(Champ.find(champ_id).type).to eq "Champs::FormattedChamp"
      end
    end
  end
end
