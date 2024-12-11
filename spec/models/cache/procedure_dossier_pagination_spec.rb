# frozen_string_literal: true

describe Cache::ProcedureDossierPagination do
  let(:instructeur) { double(id: 1) }
  let(:procedure) { double(id: 1) }
  let(:procedure_presentation) { double(instructeur:, procedure:) }
  let(:instance) { described_class.new(procedure_presentation:, statut: 'a-suivre') }

  before do
    instance.save_context(ids: cached_ids, incoming_page: nil)
  end

  describe 'next_dossier_id' do
    context 'when procedure.dossiers.by_statut has only one page' do
      let(:cached_ids) { [3, 4] }
      before do
        allow(instance).to receive(:fetch_all_ids).and_return(cached_ids)
      end

      it 'find next until the end' do
        expect(instance.next_dossier_id(from_id: cached_ids.last)).to eq(nil)
        expect(instance.next_dossier_id(from_id: cached_ids.first)).to eq(cached_ids.last)
      end
    end

    context 'when procedure.dossiers.by_statut has more than one page' do
      let(:cached_ids) { [2, 3, 4] }
      let(:next_page_ids) { (0..10).to_a }

      subject { instance.next_dossier_id(from_id: cached_ids.last) }
      before do
        allow(instance).to receive(:fetch_all_ids).and_return(next_page_ids)
      end

      it 'refreshes paginated_ids' do
        expect { subject }.to change { instance.send(:ids) }.from(cached_ids).to(next_page_ids)
      end
    end

    context 'when procedure.dossiers.by_statut does not include searched dossiers anymore' do
      let(:cached_ids) { [] }
      let(:next_page_ids) { [] }
      before { allow(instance).to receive(:fetch_all_ids).and_return(next_page_ids) }

      it 'works' do
        expect(instance.next_dossier_id(from_id: 50)).to eq(nil)
      end
    end
  end

  describe 'previous_dossier_id' do
    context 'when procedure.dossiers.by_statut has only one page' do
      let(:cached_ids) { [3, 4] }
      before do
        allow(instance).to receive(:fetch_all_ids).and_return(cached_ids)
      end

      it 'find next until the end' do
        expect(instance.previous_dossier_id(from_id: cached_ids.last)).to eq(cached_ids.first)
        expect(instance.previous_dossier_id(from_id: cached_ids.first)).to eq(nil)
      end
    end

    context 'when procedure.dossiers.by_statut has more than one page' do
      let(:cached_ids) { [11, 12, 13] }
      subject { instance.previous_dossier_id(from_id: cached_ids.first) }
      let(:next_page_ids) { (11..20).to_a }
      before do
        allow(instance).to receive(:fetch_all_ids).and_return(next_page_ids)
      end

      it 'works' do
        expect { subject }.to change { instance.send(:ids) }.from(cached_ids).to(next_page_ids)
      end
    end

    context 'when procedure.dossiers.by_statut does not include searched dossiers anymore' do
      let(:cached_ids) { [] }
      before { allow(instance).to receive(:fetch_all_ids).and_return([]) }

      it 'works' do
        expect(instance.previous_dossier_id(from_id: 50)).to eq(nil)
      end
    end
  end
end
