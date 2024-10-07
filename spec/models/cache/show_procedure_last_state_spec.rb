describe Cache::ShowProcedureLastState do
  let(:procedure) { create(:procedure) }
  let(:current_instructeur) { create(:instructeur) }
  let(:instance) { described_class.new(procedure:, current_instructeur:) }

  before do
    instance.persist_last_state(params: { status: 10 }, filtered_sorted_paginated_ids: paginated_ids)
  end

  describe 'next_dossier_id' do
    context 'when reaching end of list - 1' do
      let(:paginated_ids) { [2, 3, 4] }
      subject { instance.next_dossier_id(from_id: paginated_ids.last) }
      let(:all_ids) { (0..10).to_a }
      before do
        allow(instance).to receive(:fetch_all_paginated_ids).and_return(all_ids)
      end

      it 'refreshes paginated_ids' do
        expect { subject }.to change { instance.send(:paginated_ids) }.from(paginated_ids).to(all_ids)
      end
    end
  end

  describe 'previous_dossier_id' do
    context 'when reaching end of list - 1' do
      let(:paginated_ids) { [11, 12, 13] }
      subject { instance.previous_dossier_id(from_id: paginated_ids.first) }
      let(:all_ids) { (0..15).to_a }
      before do
        allow(instance).to receive(:fetch_all_paginated_ids).and_return(all_ids)
      end

      it 'works' do
        expect { subject }.to change { instance.send(:paginated_ids) }.from(paginated_ids).to(all_ids)
      end
    end
  end
end
