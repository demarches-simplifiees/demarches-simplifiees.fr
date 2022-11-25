describe BatchOperationProcessOneJob, type: :job do
  describe 'perform' do
    let(:batch_operation) do
      create(:batch_operation, :archiver,
                               options.merge(instructeur: create(:instructeur)))
    end
    let(:dossier_job) { batch_operation.dossiers.first }
    subject { BatchOperationProcessOneJob.new(batch_operation, dossier_job) }
    let(:options) { {} }

    it 'when it works' do
      allow_any_instance_of(BatchOperation).to receive(:process_one).with(dossier_job).and_return(true)
      expect { subject.perform_now }
        .to change { batch_operation.reload.success_dossier_ids }
        .from([])
        .to([dossier_job.id])
    end

    it 'when it fails for an "unknown" reason' do
      allow_any_instance_of(BatchOperation).to receive(:process_one).with(dossier_job).and_raise("boom")
      expect { subject.perform_now }.to raise_error('boom')

      expect(batch_operation.reload.failed_dossier_ids).to eq([dossier_job.id])
    end

    context 'when the dossier is out of sync (ie: someone applied a transition somewhere we do not know)' do
      let(:instructeur) { create(:instructeur) }
      let(:procedure) { create(:simple_procedure, instructeurs: [instructeur]) }
      let(:dossier) { create(:dossier, :accepte, :with_individual, archived: true, procedure: procedure) }
      let(:batch_operation) { create(:batch_operation, operation: :archiver, instructeur: instructeur, dossiers: [dossier]) }

      it 'does run process_one' do
        allow(batch_operation).to receive(:process_one).and_raise("should have been prevented")
        subject.perform_now
      end

      it 'when it fails from dossiers_safe_scope.find' do
        scope = double
        expect(scope).to receive(:find).with(dossier_job.id).and_raise(ActiveRecord::RecordNotFound)
        expect_any_instance_of(BatchOperation).to receive(:dossiers_safe_scope).and_return(scope)

        subject.perform_now

        expect(batch_operation.reload.failed_dossier_ids).to eq([])
        expect(batch_operation.dossiers).not_to include(dossier_job)
      end
    end
  end
end
