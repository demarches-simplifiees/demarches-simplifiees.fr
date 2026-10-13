# frozen_string_literal: true

describe Columns::FollowersInstructeursColumn do
  let(:procedure) { create(:procedure, :published) }
  let(:column) { procedure.find_column(label: 'Instructeurs') }
  let(:dossiers) { procedure.dossiers }

  describe '#sorted_ids' do
    let!(:dossier_z) { create(:dossier, :en_construction, procedure:) }
    let!(:dossier_a) { create(:dossier, :en_construction, procedure:) }
    let!(:dossier_without_instructeur) { create(:dossier, :en_construction, procedure:) }

    before do
      create(:follow, dossier: dossier_z, instructeur: create(:instructeur, email: 'zythum@exemple.fr'))
      create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca@exemple.fr'))
      create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca2@exemple.fr'))
    end

    it { expect(column.sorted_ids(dossiers, 'asc')).to eq([dossier_a, dossier_z, dossier_without_instructeur].map(&:id)) }
  end

  describe '#filtered_ids' do
    subject { column.filtered_ids(dossiers, { operator: 'match', value: search_terms }) }

    let!(:kept_dossier) { create(:dossier, procedure:) }
    let!(:discarded_dossier) { create(:dossier, procedure:) }

    before do
      create(:follow, dossier: kept_dossier, instructeur: create(:instructeur, email: 'me@keepmail.com'))
      create(:follow, dossier: discarded_dossier, instructeur: create(:instructeur, email: 'me@discard.com'))
    end

    context 'with a single search value' do
      let(:search_terms) { ['keepmail'] }

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'with multiple search values' do
      let(:search_terms) { ['keepmail', 'beta.gouv.fr'] }

      let(:other_kept_dossier) { create(:dossier, procedure:) }

      before do
        create(:follow, dossier: other_kept_dossier, instructeur: create(:instructeur, email: 'bazinga@beta.gouv.fr'))
      end

      it 'returns every dossier that matches any of the search terms' do
        is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
      end
    end
  end
end
