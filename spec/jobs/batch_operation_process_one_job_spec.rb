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
        .to change { batch_operation.dossier_operations.success.pluck(:dossier_id) }
        .from([])
        .to([dossier_job.id])
    end

    it 'when it fails for an "unknown" reason' do
      allow_any_instance_of(BatchOperation).to receive(:process_one).with(dossier_job).and_raise("boom")
      expect { subject.perform_now }.to raise_error('boom')

      expect(batch_operation.dossier_operations.error.pluck(:dossier_id)).to eq([dossier_job.id])
    end

    context 'when operation is "archiver"' do
      it 'archives the dossier in the batch' do
        expect { subject.perform_now }
          .to change { dossier_job.reload.archived? }
          .from(false)
          .to(true)
      end
    end

    context 'when operation is "passer_en_instruction"' do
      let(:batch_operation) do
        create(:batch_operation, :passer_en_instruction,
                                 options.merge(instructeur: create(:instructeur)))
      end

      it 'changes the dossier to en_instruction in the batch' do
        expect { subject.perform_now }
          .to change { dossier_job.reload.en_instruction? }
          .from(false)
          .to(true)
      end
    end

    context 'when operation is "accepter"' do
      let(:batch_operation) do
        create(:batch_operation, :accepter,
                                 options.merge(instructeur: create(:instructeur), motivation: 'motivation'))
      end

      it 'accepts the dossier in the batch' do
        expect { subject.perform_now }
          .to change { dossier_job.reload.accepte? }
          .from(false)
          .to(true)
      end

      it 'accepts the dossier in the batch with a motivation' do
        expect { subject.perform_now }
          .to change { dossier_job.reload.motivation }
          .from(nil)
          .to('motivation')
      end
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
