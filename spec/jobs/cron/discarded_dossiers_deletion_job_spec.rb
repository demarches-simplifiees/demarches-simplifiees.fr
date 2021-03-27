RSpec.describe Cron::DiscardedDossiersDeletionJob, type: :job do
  describe '#perform' do
    let(:instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier, :with_individual, state) }

    before do
      # hack to add passer_en_instruction and supprimer to dossier.dossier_operation_logs
      dossier.send(:log_dossier_operation, instructeur, :passer_en_instruction, dossier)
      dossier.send(:log_dossier_operation, instructeur, :supprimer, dossier)
      dossier.update_column(:hidden_at, hidden_at)

      Cron::DiscardedDossiersDeletionJob.perform_now
    end

    def operations_left
      DossierOperationLog.where(dossier_id: dossier.id).pluck(:operation)
    end

    RSpec.shared_examples "does not delete" do
      it 'does not delete it' do
        expect { dossier.reload }.not_to raise_error
      end

      it 'does not delete its operations logs' do
        expect(operations_left).to match_array(["passer_en_instruction", "supprimer"])
      end
    end

    RSpec.shared_examples "does delete" do
      it 'does delete it' do
        expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes its operations logs except supprimer' do
        expect(operations_left).to eq(["supprimer"])
      end
    end

    [:en_construction, :en_instruction, :accepte, :refuse, :sans_suite].each do |state|
      context "with a dossier #{state}" do
        let(:state) { state }

        context 'not hidden' do
          let(:hidden_at) { nil }

          include_examples "does not delete"
        end

        context 'hidden not so long ago' do
          let(:hidden_at) { 1.week.ago + 1.hour }

          include_examples "does not delete"
        end
      end
    end

    [:en_construction, :accepte, :refuse, :sans_suite].each do |state|
      context "with a dossier #{state}" do
        let(:state) { state }

        context 'hidden long ago' do
          let(:hidden_at) { 1.week.ago - 1.hour }

          include_examples "does delete"
        end
      end
    end
  end
end
