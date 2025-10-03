# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251003normalizeProcedurePresentationFiltersTask do
    describe ".collection" do
      subject(:collection) { described_class.collection }

      let(:procedure) { create(:procedure, :published) }
      let(:instructeur) { create(:instructeur) }
      let!(:assign_to) { create(:assign_to, procedure:, instructeur:) }
      let!(:procedure_presentation) { create(:procedure_presentation, assign_to:) }

      it "returns procedure presentations" do
        expect(collection).to include(procedure_presentation)
      end
    end

    describe "#process" do
      let(:procedure) { create(:procedure, :published) }
      let(:instructeur) { create(:instructeur) }
      let(:assign_to) { create(:assign_to, procedure:, instructeur:) }
      let!(:procedure_presentation) { create(:procedure_presentation, assign_to:) }
      let(:column) { procedure.find_column(label: "Demandeur") }

      before do
        raw_filter_payload = {
          "id" => column.h_id,
          "filter" => { "operator" => "match", "value" => ["Valeur avec retour\r\n"] }
        }

        procedure_presentation.update_column(:tous_filters, [raw_filter_payload])
        procedure_presentation.reload
      end

      it "normalizes stored filter values" do
        expect {
          described_class.new.process(procedure_presentation)
        }.to change {
          procedure_presentation.reload.read_attribute_before_type_cast(:tous_filters).first["filter"]["value"].first
        }.from("Valeur avec retour\r\n").to("Valeur avec retour\n")
      end

      it "updates the deserialized objects" do
        described_class.new.process(procedure_presentation)

        normalized_filter = procedure_presentation.reload.tous_filters.first

        expect(normalized_filter.filter_value).to eq(["Valeur avec retour\n"])
      end

      it "does nothing when values are already normalized" do
        described_class.new.process(procedure_presentation)

        expect {
          described_class.new.process(procedure_presentation.reload)
        }.not_to change {
          procedure_presentation.reload.read_attribute_before_type_cast(:tous_filters)
        }
      end
    end
  end
end
