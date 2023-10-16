describe DataFixer::DossierChampsMissing do
  describe '#fix' do
    let(:procedure) { create(:procedure, :with_datetime, :with_dossier_link) }
    let(:dossier) { create(:dossier, procedure:) }

    context 'when dossier does not have a fork' do
      before { dossier.champs_public.first.destroy }
      subject { described_class.new(dossier:).fix }

      it 'add missing champs to the dossier' do
        expect { subject }.to change { dossier.champs_public.count }.from(1).to(2)
      end

      it 'returns number of added champs' do
        expect(subject).to eq(1)
      end
    end

    context 'when dossier have a fork' do
      before { dossier.champs_public.first.destroy }
      let(:create_fork) { dossier.find_or_create_editing_fork(dossier.user) }
      subject do
        create_fork
        described_class.new(dossier:).fix
      end

      it 'add missing champs to the fork too' do
        expect { subject }.to change { create_fork.champs_public.count }.from(1).to(2)
      end

      it 'sums number of added champs for dossier and editing_fork_origin_id' do
        expect(subject).to eq(2)
      end
    end
  end
end
