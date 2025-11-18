# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251118destroyInstructeursProcedureOfInstructeursRemovedFromProcedureTask do
    let(:procedure_1) { create(:procedure) }
    let(:instructeur_1) { create(:instructeur) }
    let(:instructeur_2) { create(:instructeur) }
    let!(:groupe_instructeur_1_1) { create(:groupe_instructeur, procedure: procedure_1, instructeurs: [instructeur_1]) }
    let!(:groupe_instructeur_1_2) { create(:groupe_instructeur, procedure: procedure_1, instructeurs: [instructeur_1, instructeur_2]) }
    let(:procedure_2) { create(:procedure) }
    let!(:groupe_instructeur_2_1) { create(:groupe_instructeur, procedure: procedure_2, instructeurs: [instructeur_2]) }

    describe "#collection" do
      subject(:collection) { described_class.collection }

      it "returns instructeur_ids group by procedure_id" do
        expect(collection.map(&:first)).to match_array([procedure_1.id, procedure_2.id])
        expect(collection.to_h[procedure_1.id]).to match_array([instructeur_1.id, instructeur_2.id])
        expect(collection.to_h[procedure_2.id]).to eq([instructeur_2.id])
      end
    end

    describe "#process" do
      subject(:process) { described_class.process([procedure_2.id, instructeur_ids]) }

      let(:instructeur_ids) { procedure_2.instructeur_ids }

      context "when there is a match " do
        let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur: instructeur_2, procedure: procedure_2) }

        it "does not destroy matching instructeurs_procedure" do
          subject

          expect(InstructeursProcedure.all).to include(instructeur_procedure)
        end
      end

      context 'when there is no match' do
        let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur: instructeur_1, procedure: procedure_2) }

        it "destroys non-matching instructeurs_procedure" do
          subject

          expect(InstructeursProcedure.all).not_to include(instructeur_procedure)
        end
      end
    end
  end
end
