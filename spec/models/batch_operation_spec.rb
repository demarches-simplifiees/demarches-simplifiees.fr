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

  describe 'process' do
    let(:procedure) { create(:procedure, :with_instructeur) }

    subject do
      create(:batch_operation, instructeur: procedure.instructeurs.first,
                               operation: operation,
                               dossiers: dossiers)
    end

    context 'archive' do

      let(:operation) { BatchOperation.operations.fetch(:archiver) }
      let(:dossier_accepte) { create(:dossier, :accepte, procedure: procedure) }
      let(:dossier_refuse) { create(:dossier, :refuse, procedure: procedure) }
      let(:dossier_classe_sans_suite) { create(:dossier, :sans_suite, procedure: procedure) }
      let(:dossiers) { [dossier_accepte, dossier_refuse, dossier_classe_sans_suite] }

      it 'works' do
        expect { subject.process() }
          .to change { dossiers.map(&:reload).map(&:archived) }
          .from(dossiers.map { false })
          .to(dossiers.map { true })
      end
    end
  end
end
