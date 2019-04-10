require 'rails_helper'

RSpec.describe AutoReceiveDossiersForProcedureJob, type: :job do
  describe "perform" do
    let(:date) { Time.utc(2017, 9, 1, 10, 5, 0) }
    let(:instruction_date) { date + 120 }

    let(:procedure) { create(:procedure, :with_gestionnaire) }
    let(:nouveau_dossier1) { create(:dossier, :en_construction, procedure: procedure) }
    let(:nouveau_dossier2) { create(:dossier, :en_construction, procedure: procedure) }
    let(:dossier_recu) { create(:dossier, :en_instruction, procedure: procedure) }
    let(:dossier_brouillon) { create(:dossier, procedure: procedure) }

    before do
      Timecop.freeze(date)
      dossiers = [
        nouveau_dossier1,
        nouveau_dossier2,
        dossier_recu,
        dossier_brouillon
      ]

      create(:attestation_template, procedure: procedure)
      AutoReceiveDossiersForProcedureJob.new.perform(procedure.id, state)

      dossiers.each(&:reload)
    end

    after { Timecop.return }

    context "with some dossiers" do
      context "en_construction" do
        let(:state) { Dossier.states.fetch(:en_instruction) }
        let(:last_operation) { nouveau_dossier1.dossier_operation_logs.last }

        it {
          expect(nouveau_dossier1.en_instruction?).to be true
          expect(nouveau_dossier1.en_instruction_at).to eq(date)
          expect(last_operation.operation).to eq('passer_en_instruction')
          expect(last_operation.automatic_operation?).to be_truthy

          expect(nouveau_dossier2.en_instruction?).to be true
          expect(nouveau_dossier2.en_instruction_at).to eq(date)

          expect(dossier_recu.en_instruction?).to be true
          expect(dossier_recu.en_instruction_at).to eq(instruction_date)

          expect(dossier_brouillon.brouillon?).to be true
          expect(dossier_brouillon.en_instruction_at).to eq(nil)
        }
      end

      context "accepte" do
        let(:state) { Dossier.states.fetch(:accepte) }
        let(:last_operation) { nouveau_dossier1.dossier_operation_logs.last }

        it {
          expect(nouveau_dossier1.accepte?).to be true
          expect(nouveau_dossier1.en_instruction_at).to eq(date)
          expect(nouveau_dossier1.processed_at).to eq(date)
          expect(nouveau_dossier1.attestation).to be_present
          expect(last_operation.operation).to eq('accepter')
          expect(last_operation.automatic_operation?).to be_truthy

          expect(nouveau_dossier2.accepte?).to be true
          expect(nouveau_dossier2.en_instruction_at).to eq(date)
          expect(nouveau_dossier2.processed_at).to eq(date)
          expect(nouveau_dossier2.attestation).to be_present

          expect(dossier_recu.en_instruction?).to be true
          expect(dossier_recu.en_instruction_at).to eq(instruction_date)
          expect(dossier_recu.processed_at).to eq(nil)

          expect(dossier_brouillon.brouillon?).to be true
          expect(dossier_brouillon.en_instruction_at).to eq(nil)
          expect(dossier_brouillon.processed_at).to eq(nil)
        }
      end
    end
  end
end
