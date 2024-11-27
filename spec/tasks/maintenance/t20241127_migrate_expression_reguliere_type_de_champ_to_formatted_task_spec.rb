# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241127MigrateExpressionReguliereTypeDeChampToFormattedTask do
    let(:type_de_champ_regex) { create(:type_de_champ_expression_reguliere) }
    let(:type_de_champ_text) { create(:type_de_champ_text) }

    describe "#process" do
      subject(:process) { described_class.process(type_de_champ_regex) }

      it 'works' do
        process
        expect(TypeDeChamp.find(type_de_champ_regex.id).type_champ).to eq 'formatted'
        expect(TypeDeChamp.find(type_de_champ_regex.id).options["formatted_mode"]).to eq 'advanced'
      end
    end

    describe '#collection' do
      it "works" do
        type_de_champ_regex
        type_de_champ_text
        expect(described_class.collection.map(&:type_champ)).to eq(["expression_reguliere"])
      end
    end
  end
end
