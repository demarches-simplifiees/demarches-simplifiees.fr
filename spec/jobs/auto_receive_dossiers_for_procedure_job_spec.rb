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
      nouveau_dossier1
      nouveau_dossier2
      dossier_recu
      dossier_brouillon

      create(:attestation_template, procedure: procedure)
      AutoReceiveDossiersForProcedureJob.new.perform(procedure.id, state)
    end

    after { Timecop.return }

    context "with some dossiers" do
      context "en_construction" do
        let(:state) { Dossier.states.fetch(:en_instruction) }

        it {
          expect(nouveau_dossier1.reload.en_instruction?).to be true
          expect(nouveau_dossier1.reload.en_instruction_at).to eq(date)

          expect(nouveau_dossier2.reload.en_instruction?).to be true
          expect(nouveau_dossier2.reload.en_instruction_at).to eq(date)

          expect(dossier_recu.reload.en_instruction?).to be true
          expect(dossier_recu.reload.en_instruction_at).to eq(instruction_date)

          expect(dossier_brouillon.reload.brouillon?).to be true
          expect(dossier_brouillon.reload.en_instruction_at).to eq(nil)
        }
      end

      context "accepte" do
        let(:state) { Dossier.states.fetch(:accepte) }

        it {
          expect(nouveau_dossier1.reload.accepte?).to be true
          expect(nouveau_dossier1.reload.en_instruction_at).to eq(date)
          expect(nouveau_dossier1.reload.processed_at).to eq(date)
          expect(nouveau_dossier1.reload.attestation).to be_present

          expect(nouveau_dossier2.reload.accepte?).to be true
          expect(nouveau_dossier2.reload.en_instruction_at).to eq(date)
          expect(nouveau_dossier2.reload.processed_at).to eq(date)
          expect(nouveau_dossier2.reload.attestation).to be_present

          expect(dossier_recu.reload.en_instruction?).to be true
          expect(dossier_recu.reload.en_instruction_at).to eq(instruction_date)
          expect(dossier_recu.reload.processed_at).to eq(nil)

          expect(dossier_brouillon.reload.brouillon?).to be true
          expect(dossier_brouillon.reload.en_instruction_at).to eq(nil)
          expect(dossier_brouillon.reload.processed_at).to eq(nil)
        }
      end
    end
  end
end
