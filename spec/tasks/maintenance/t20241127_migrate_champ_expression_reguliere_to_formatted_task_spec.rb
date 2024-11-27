# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241127MigrateChampExpressionReguliereToFormattedTask do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: "expression_reguliere" }, { type: "text" }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }

    describe "#process" do
      let(:batch_of_champs) { Champ.where(type: ["Champs::ExpressionReguliereChamp", "Champs::FormattedChamp"]).in_batches }
      subject(:process) { described_class.process(batch_of_champs) }

      it "works" do
        dossier
        process
        expect(Champ.first.type).to eq("Champs::FormattedChamp")
      end
    end

    describe '#collection' do
      it "works" do
        dossier # create dossier
        expect(described_class.collection.relation.map(&:type)).to eq(["Champs::ExpressionReguliereChamp"])
      end
    end
  end
end
