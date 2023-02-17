RSpec.describe Cron::DeclarativeProceduresJob, type: :job do
  describe "perform" do
    let(:date) { Time.utc(2017, 9, 1, 10, 5, 0) }
    let(:instruction_date) { date + 120 }

    let(:state) { nil }
    let(:procedure) { create(:procedure, :published, :for_individual, :with_instructeur, declarative_with_state: state) }
    let(:nouveau_dossier1) { create(:dossier, :en_construction, :with_individual, :with_attestation, procedure: procedure) }
    let(:nouveau_dossier2) { create(:dossier, :en_construction, :with_individual, :with_attestation, procedure: procedure) }
    let(:dossier_recu) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
    let(:dossier_brouillon) { create(:dossier, procedure: procedure) }
    let(:dossier_repasse_en_construction) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }

    before do
        Timecop.freeze(date)
        dossier_repasse_en_construction&.touch(:declarative_triggered_at)
      end

    subject(:perform_job) do
    dossiers = [
      nouveau_dossier1,
      nouveau_dossier2,
      dossier_recu,
      dossier_brouillon,
      dossier_repasse_en_construction
    ].compact

    Cron::DeclarativeProceduresJob.new.perform

    dossiers.each(&:reload)
  end

    after { Timecop.return }

    context "with some dossiers" do
      context "en_construction" do
        let(:state) { Dossier.states.fetch(:en_instruction) }
        let(:last_operation) { nouveau_dossier1.dossier_operation_logs.last }

        it {
          perform_job
          expect(nouveau_dossier1.en_instruction?).to be_truthy
          expect(nouveau_dossier1.en_instruction_at).to eq(date)
          expect(last_operation.operation).to eq('passer_en_instruction')
          expect(last_operation.automatic_operation?).to be_truthy

          expect(nouveau_dossier2.en_instruction?).to be_truthy
          expect(nouveau_dossier2.en_instruction_at).to eq(date)

          expect(dossier_recu.en_instruction?).to be_truthy
          expect(dossier_recu.en_instruction_at).to eq(instruction_date)

          expect(dossier_brouillon.brouillon?).to be_truthy
          expect(dossier_brouillon.en_instruction_at).to eq(nil)

          expect(dossier_repasse_en_construction.en_construction?).to be_truthy
        }
      end

      context "accepte" do
        let(:state) { Dossier.states.fetch(:accepte) }
        let(:last_operation) { nouveau_dossier1.dossier_operation_logs.last }

        it {
          perform_job
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

        context "having etablissement in degraded_mode" do
          let(:procedure) { create(:procedure, :published, :with_instructeur, for_individual: false, declarative_with_state: state) }
          let(:nouveau_dossier1) { create(:dossier, :en_construction, :with_entreprise, :with_attestation, procedure: procedure, as_degraded_mode: false) }
          let(:nouveau_dossier2) { create(:dossier, :en_construction, :with_entreprise, :with_attestation, procedure: procedure, as_degraded_mode: true) }
          let(:dossier_recu) { nil }
          let(:dossier_repasse_en_construction) { nil }

          before do
            expect(nouveau_dossier2).to_not receive(:accepter_automatiquement)
            expect(Sentry).to_not receive(:capture_exception)
          end

          it {
            perform_job
            expect(nouveau_dossier1).to be_accepte
            expect(nouveau_dossier2).to be_en_construction
          }
        end
      end
    end
  end

  describe 'safer perform' do
      let(:state) { Dossier.states.fetch(:en_instruction) }

      it 'works no matter if one raise' do
        procedure_1 = instance_double("Procedure")
        expect(procedure_1).to receive(:process_dossiers!)
        procedure_2 = instance_double("Procedure")
        expect(procedure_2).to receive(:process_dossiers!).and_raise("boom")
        procedure_3 = double(process_dossiers!: true)
        expect(procedure_3).to receive(:process_dossiers!)

        expect(Procedure).to receive_message_chain(:declarative, :find_each).and_yield(procedure_1).and_yield(procedure_2).and_yield(procedure_3)
        Cron::DeclarativeProceduresJob.perform_now
      end
    end
end
