describe BatchOperation, type: :model do
  describe 'association' do
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to belong_to(:instructeur) }
    it { is_expected.to have_and_belong_to_many(:groupe_instructeurs) }
  end

  describe 'attributes' do
    subject { BatchOperation.new }
    it { expect(subject.payload).to eq({}) }
    it { expect(subject.failed_dossier_ids).to eq([]) }
    it { expect(subject.success_dossier_ids).to eq([]) }
    it { expect(subject.run_at).to eq(nil) }
    it { expect(subject.finished_at).to eq(nil) }
    it { expect(subject.operation).to eq(nil) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:operation) }
  end

  describe '#enqueue_all' do
    context 'given dossier_ids in instructeur procedures' do
      subject do
        create(:batch_operation, :archiver, instructeur: create(:instructeur))
      end

      it 'enqueues as many BatchOperationProcessOneJob as dossiers_ids' do
        expect { subject.enqueue_all() }
          .to have_enqueued_job(BatchOperationProcessOneJob)
          .with(subject, subject.dossiers.first)
          .with(subject, subject.dossiers.second)
          .with(subject, subject.dossiers.third)
      end

      it 'pass through dossiers_safe_scope' do
        expect(subject).to receive(:dossiers_safe_scope).and_return(subject.dossiers)
        subject.enqueue_all
      end
    end
  end

  describe '#track_processed_dossier' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:simple_procedure, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, :accepte, :with_individual, archived: true, procedure: procedure) }
    let(:batch_operation) { create(:batch_operation, operation: :archiver, instructeur: instructeur, dossiers: [dossier]) }

    it 'unlock the dossier' do
      expect { batch_operation.track_processed_dossier(true, dossier) }
        .to change { dossier.reload.batch_operation }
        .from(batch_operation)
        .to(nil)
    end

    context 'when it succeed' do
      it 'pushes dossier_job id to batch_operation.success_dossier_ids' do
        expect { batch_operation.track_processed_dossier(true, dossier) }
          .to change { batch_operation.reload.success_dossier_ids }
          .from([])
          .to([dossier.id])
      end
    end

    context 'when it succeed after a failure' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, instructeur: instructeur, dossiers: [dossier], failed_dossier_ids: [dossier.id]) }
      it 'remove former dossier id from failed_dossier_ids' do
        expect { batch_operation.track_processed_dossier(true, dossier) }
          .to change { batch_operation.reload.failed_dossier_ids }
          .from([dossier.id])
          .to([])
      end
    end

    context 'when it fails' do
      it 'pushes dossier_job id to batch_operation.failed_dossier_ids' do
        expect { batch_operation.track_processed_dossier(false, dossier) }
          .to change { batch_operation.reload.failed_dossier_ids }
          .from([])
          .to([dossier.id])
      end
    end

    context 'when it is the first job' do
      it 'sets run_at at first' do
        expect { batch_operation.track_processed_dossier(false, dossier) }
          .to change { batch_operation.reload.run_at }
          .from(nil)
          .to(anything)
      end
    end

    context 'when it is the second job (meaning run_at was already set) but not the last' do
      let(:batch_operation) { create(:batch_operation, operation: :archiver, instructeur: instructeur, dossiers: [dossier], run_at: 2.days.ago) }
      it 'does not change run_at' do
        expect { batch_operation.track_processed_dossier(true, dossier) }
          .not_to change { batch_operation.reload.run_at }
      end
    end

    context 'when it is the last job' do
      it 'sets finished_at' do
        expect { batch_operation.track_processed_dossier(true, dossier) }
          .to change { batch_operation.reload.finished_at }
          .from(nil)
          .to(anything)
      end
    end
  end

  describe '#dossiers_safe_scope (with archiver)' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:simple_procedure, instructeurs: [instructeur]) }
    let(:batch_operation) { create(:batch_operation, operation: :archiver, instructeur: instructeur, dossiers: [dossier]) }

    context 'when dossier is valid' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure) }

      it 'find dosssier' do
        expect(batch_operation.dossiers_safe_scope).to include(dossier)
      end
    end
    context 'when dossier is already arcvhied' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, archived: true, procedure: procedure) }

      it 'skips dosssier is already archived' do
        expect(batch_operation.dossiers_safe_scope).not_to include(dossier)
      end
    end

    context 'when dossier is not in state termine' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }

      it 'does not enqueue any job' do
        expect(batch_operation.dossiers_safe_scope).not_to include(dossier)
      end
    end

    context 'when dossier is not in instructeur procedures' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: create(:simple_procedure)) }

      it 'does not enqueues any BatchOperationProcessOneJob' do
        expect(batch_operation.dossiers_safe_scope).not_to include(dossier)
      end
    end
  end

  describe '#safe_create!' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:simple_procedure, instructeurs: [instructeur]) }
    subject { BatchOperation.safe_create!(instructeur: instructeur, operation: :archiver, dossier_ids: [dossier.id]) }

    context 'success with divergent list of dossier_ids' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, archived: true, procedure: procedure) }

      it 'does not keep archived dossier within batch_operation.dossiers' do
        expect(subject.dossiers).not_to include(dossier)
      end

      it 'enqueue a BatchOperationEnqueueAllJob' do
        expect { subject }.to have_enqueued_job(BatchOperationEnqueueAllJob)
      end
    end

    context 'with dossier already in a batch batch_operation' do
      let(:dossier) { create(:dossier, :accepte, :with_individual, batch_operation: create(:batch_operation, :archiver, instructeur: instructeur), procedure: procedure) }

      it 'does not keep dossier in batch_operation' do
        expect(subject.dossiers).not_to include(dossier)
      end
    end
  end
end
