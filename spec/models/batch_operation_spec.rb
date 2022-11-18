describe BatchOperation, type: :model do
  describe 'association' do
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to belong_to(:instructeur) }
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

  describe 'enqueue_all' do
    context 'given dossier_ids not in instructeur procedures' do
      subject do
        create(:batch_operation, :archiver, instructeur: create(:instructeur), invalid_instructeur: create(:instructeur))
      end

      it 'does not enqueues any BatchOperationProcessOneJob' do
        expect { subject.enqueue_all() }
          .not_to have_enqueued_job(BatchOperationProcessOneJob)
      end
    end

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
    end
  end
end
