describe BatchOperationJob, type: :job do
  describe 'perform' do
    let(:batch_operation) do
      create(:batch_operation, :archiver,
                               options.merge(instructeur: create(:instructeur)))
    end
    let(:dossier_job) { batch_operation.dossiers.first }
    subject { BatchOperationJob.new(batch_operation, dossier_job) }
    let(:options) { {} }

    it 'just call the process one' do
      expect { subject.perform_now }
        .to change { dossier_job.reload.archived }
        .from(false)
        .to(true)
    end

    it 'unlock the dossier' do
      expect { subject.perform_now }
        .to change { dossier_job.reload.batch_operation }
        .from(batch_operation)
        .to(nil)
    end

    context 'when it succeed' do
      it 'pushes dossier_job id to batch_operation.success_dossier_ids' do
        expect { subject.perform_now }
          .to change { batch_operation.success_dossier_ids }
          .from([])
          .to([dossier_job.id])
      end
    end

    context 'when it fails' do
      it 'pushes dossier_job id to batch_operation.failed_dossier_ids' do
        expect(batch_operation).to receive(:process_one).with(dossier_job).and_raise("KO")
        expect { subject.perform_now }.to raise_error("KO")
        expect(batch_operation.reload.failed_dossier_ids).to eq([dossier_job.id])
      end
    end

    context 'when it is the first job' do
      it 'sets run_at at first' do
        run_at = 2.minutes.ago
        Timecop.freeze(run_at) do
          expect { subject.perform_now }
            .to change { batch_operation.run_at }
            .from(nil)
            .to(run_at)
        end
      end
    end

    context 'when it is the second job (meaning run_at was already set) but not the last' do
      let(:preview_run_at) { 2.days.ago }
      let(:options) { { run_at: preview_run_at } }
      it 'does not change run_at' do
        expect { subject.perform_now }.not_to change { batch_operation.reload.run_at }
      end
    end

    context 'when it is the last job' do
      before do
        batch_operation.dossiers
          .where.not(id: dossier_job.id)
          .update_all(batch_operation_id: nil)
      end
      it 'sets finished_at' do
        finished_at = Time.zone.now
        Timecop.freeze(finished_at) do
          expect { subject.perform_now }
            .to change { batch_operation.reload.finished_at }
            .from(nil)
            .to(finished_at)
        end
      end
    end
  end
end
