# frozen_string_literal: true

module Maintenance
  RSpec.describe FixAvisExpertsProcedureMismatchTask do
    describe "#collection" do
      subject(:collection) { described_class.new.collection }

      let!(:mismatched_avis) do
        expert = create(:expert)
        procedure1 = create(:procedure)
        procedure2 = create(:procedure)
        dossier = create(:dossier, procedure: procedure2)
        wrong_experts_procedure = create(:experts_procedure, expert: expert, procedure: procedure1)

        create(:avis,
          dossier: dossier,
          expert: expert,
          experts_procedure: wrong_experts_procedure)
      end

      let!(:correct_avis) do
        expert = create(:expert)
        procedure = create(:procedure)
        dossier = create(:dossier, procedure: procedure)
        experts_procedure = create(:experts_procedure, expert: expert, procedure: procedure)

        create(:avis,
          dossier: dossier,
          expert: expert,
          experts_procedure: experts_procedure)
      end

      it "only returns avis with mismatched procedure ids" do
        expect(collection).to include(mismatched_avis)
        expect(collection).not_to include(correct_avis)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(avis) }

      let(:expert) { create(:expert) }
      let(:procedure1) { create(:procedure) }
      let(:procedure2) { create(:procedure) }
      let(:dossier) { create(:dossier, procedure: procedure2) }

      let!(:wrong_experts_procedure) do
        create(:experts_procedure, expert: expert, procedure: procedure1)
      end

      let(:avis) do
        create(:avis,
          dossier: dossier,
          expert: expert,
          experts_procedure: wrong_experts_procedure)
      end

      it "fixes the experts_procedure association" do
        expect(avis.experts_procedure.procedure_id).to eq(procedure1.id)
        expect(avis.dossier.procedure.id).to eq(procedure2.id)

        process

        avis.reload
        expect(avis.experts_procedure.procedure_id).to eq(procedure2.id)
        expect(avis.dossier.procedure.id).to eq(procedure2.id)
      end

      context "when the correct experts_procedure already exists" do
        let!(:correct_experts_procedure) do
          create(:experts_procedure, expert: expert, procedure: procedure2)
        end

        it "uses the existing experts_procedure" do
          process

          avis.reload
          expect(avis.experts_procedure).to eq(correct_experts_procedure)
        end
      end

      context "when the avis has an invalid question_answer" do
        let(:avis) do
          create(:avis,
            dossier: dossier,
            expert: expert,
            experts_procedure: wrong_experts_procedure,
            question_label: "Some question",
            question_answer: nil)
        end

        it "fixes the experts_procedure association without validation errors" do
          expect(avis).not_to be_valid
          expect { process }.not_to raise_error

          avis.reload
          expect(avis.experts_procedure.procedure_id).to eq(procedure2.id)
        end
      end
    end
  end
end
