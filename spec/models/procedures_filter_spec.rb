describe ProceduresFilter do
  let(:admin) { create(:administrateur) }
  let(:params) { ActionController::Parameters.new(filters) }
  let(:subject) { ProceduresFilter.new(admin, params) }

  context 'without filter' do
    let(:filters) { {} }
    let!(:draft_procedure)     { create(:procedure, administrateur: admin3) }
    let!(:published_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2, administrateur: admin1) }
    let!(:closed_procedure)    { create(:procedure, :closed, administrateur: admin2) }
    let(:admin1) { create(:administrateur) }
    let(:admin2) { create(:administrateur) }
    let(:admin3) { create(:administrateur) }

    it 'returns only published and closed procedures' do
      expect(subject.procedures_result).to include(published_procedure)
      expect(subject.procedures_result).to include(closed_procedure)
      expect(subject.procedures_result).not_to include(draft_procedure)
    end

    context 'with view_admins param' do
      it 'returns admins of the procedures' do
        expect(subject.admins_result).to include(admin1)
        expect(subject.admins_result).to include(admin2)
        expect(subject.admins_result).not_to include(admin3)
      end
    end
  end

  context 'with zone filter' do
    let(:zone1) { create(:zone) }
    let(:zone2) { create(:zone) }
    let!(:procedure1) { create(:procedure, :published, zones: [zone1]) }
    let!(:procedure2) { create(:procedure, :published, zones: [zone1, zone2]) }
    let(:filters) { { zone_ids: [zone2.id] } }

    it 'returns only procedures for specified zones' do
      expect(subject.procedures_result).to include(procedure2)
      expect(subject.procedures_result).not_to include(procedure1)
    end
  end

  context 'with published status filter' do
    let!(:procedure1) { create(:procedure, :published) }
    let!(:procedure2) { create(:procedure, :closed) }
    let(:filters) { { statuses: ['publiee'] } }

    it 'returns only published procedures' do
      expect(subject.procedures_result).to include(procedure1)
      expect(subject.procedures_result).not_to include(procedure2)
    end
  end

  context 'with closed status filter' do
    let!(:procedure1) { create(:procedure, :published) }
    let!(:procedure2) { create(:procedure, :closed) }
    let(:filters) { { statuses: ['close'] } }

    it 'returns only closed procedures' do
      expect(subject.procedures_result).to include(procedure2)
      expect(subject.procedures_result).not_to include(procedure1)
    end
  end

  context 'with specific date filter' do
    let(:after) { '2022-06-30' }
    let(:after_date) { Date.parse(after) }
    let!(:procedure1) { create(:procedure, :published, published_at: after_date + 1.day) }
    let!(:procedure2) { create(:procedure, :published, published_at: after_date + 2.days) }
    let!(:procedure3) { create(:procedure, :published, published_at: after_date - 1.day) }

    let(:filters) { { from_publication_date: after } }

    it 'returns only procedures published after specific date' do
      expect(subject.procedures_result).to include(procedure1)
      expect(subject.procedures_result).to include(procedure2)
      expect(subject.procedures_result).not_to include(procedure3)
    end
  end

  context 'with bad date input' do
    let(:after) { 'oops' }
    let!(:procedure1) { create(:procedure, :published) }
    let(:filters) { { from_publication_date: after } }

    it 'ignores date filter' do
      expect(subject.procedures_result).to include(procedure1)
    end
  end
end
