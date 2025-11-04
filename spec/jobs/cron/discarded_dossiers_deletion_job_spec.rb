# frozen_string_literal: true

RSpec.describe Cron::DiscardedDossiersDeletionJob, type: :job do
  describe '#perform' do
    let(:instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier, :with_individual, state) }
    let(:dossier_2) { create(:dossier, :with_individual, state) }

    before do
      # hack to add passer_en_instruction and supprimer to dossier.dossier_operation_logs
      dossier.send(:log_dossier_operation, instructeur, :passer_en_instruction, dossier)
      dossier.send(:log_dossier_operation, instructeur, :supprimer, dossier)
      dossier.update_columns(hidden_by_user_at: hidden_at, hidden_by_administration_at: hidden_at)
      dossier.update_column(:hidden_by_reason, "user_request")
      dossier_2.update_columns(hidden_by_expired_at: hidden_at)
      dossier_2.update_column(:hidden_by_reason, "expired")
    end

    subject do
      Cron::DiscardedDossiersDeletionJob.perform_now
    end

    def operations_left
      DossierOperationLog.where(dossier_id: dossier.id).pluck(:operation)
    end

    RSpec.shared_examples "does not delete" do
      before { subject }

      it 'does not delete it' do
        expect { dossier.reload }.not_to raise_error
        expect { dossier_2.reload }.not_to raise_error
      end

      it 'does not delete its operations logs' do
        expect(operations_left).to match_array(["passer_en_instruction", "supprimer"])
      end
    end

    RSpec.shared_examples "does delete" do
      before { subject }

      it 'does delete it' do
        expect { dossier.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { dossier_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
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
          let(:hidden_at) { 2.weeks.ago + 1.hour }

          include_examples "does not delete"
        end
      end
    end

    [:en_construction, :accepte, :refuse, :sans_suite].each do |state|
      context "with a dossier #{state}" do
        let(:state) { state }

        context 'hidden long ago' do
          let(:hidden_at) { 2.weeks.ago - 1.hour }
          include_examples "does delete"

          it "uses relevant deleted_at depending on user hidden it and state" do
            subject

            if state == :en_construction
              expect(DeletedDossier.find_by(dossier_id: dossier.id).deleted_at).to be_within(1.second).of(dossier.hidden_by_user_at)
            else
              expect(DeletedDossier.find_by(dossier_id: dossier.id).deleted_at).to be_within(1.second).of(Time.current)
            end

            # dossier not hidden:
            expect(DeletedDossier.find_by(dossier_id: dossier_2.id).deleted_at).to be_within(1.second).of(Time.current)
          end
        end
      end
    end

    context "error on error" do
      let(:state) { :en_construction }
      let(:hidden_at) { 1.month.ago }
      let(:failing_dossier) { create(:dossier, :en_construction, hidden_by_user_at: 5.weeks.ago, hidden_by_reason: "user_request") }

      before do
        failing_dossier.update_column(:hidden_by_reason, nil) # recurrent error previously causing job to crash
        expect(Sentry).to receive(:capture_exception).with(instance_of(KeyError), extra: { dossier: failing_dossier.id })
      end

      include_examples "does delete"
    end
  end
end
