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

      it "returns the procedure presentation" do
        expect(collection).to include(procedure_presentation)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(procedure_presentation) }

      let(:procedure) { create(:procedure, :published) }
      let(:instructeur) { create(:instructeur) }
      let(:assign_to) { create(:assign_to, procedure:, instructeur:) }
      let!(:procedure_presentation) { create(:procedure_presentation, assign_to:) }
      let(:column) { procedure.find_column(label: "Demandeur") }

      context "when filters contain control characters" do
        before do
          stored_filter = FilteredColumn.new(
            column: column,
            filter: { operator: "match", value: ["Valeur avec retour\r\n"] }
          )
          procedure_presentation.update!(tous_filters: [stored_filter])
        end

        it "normalizes the stored filters" do
          process

          normalized_filter = procedure_presentation.reload.tous_filters.first

          expect(normalized_filter.filter_value).to eq(["Valeur avec retour\n"])
          expect(normalized_filter.filter_operator).to eq("match")
        end

        it "skips already normalized filters" do
          process
          expect {
            described_class.process(procedure_presentation.reload)
          }.not_to change { procedure_presentation.reload.tous_filters.map(&:filter_value) }
        end
      end

      context "when filters are blank" do
        before { procedure_presentation.update!(tous_filters: []) }

        it "does not persist changes" do
          expect { process }.not_to change { procedure_presentation.reload.updated_at }
        end
      end
    end
  end
end
