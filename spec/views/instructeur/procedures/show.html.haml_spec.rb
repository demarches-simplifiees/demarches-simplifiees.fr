describe 'instructeurs/procedures/show.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }

  before do
    assign(:procedure, procedure)
    assign(:statut, "a-suivre")
    assign(:current_filters, [])
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
    assign(:followed_dossiers, [])
    assign(:dossiers_followed_filtered_count, 0)
    assign(:termines_dossiers, [])
    assign(:dossiers_termines_filtered_count, 0)
    assign(:all_state_dossiers, [1])
    assign(:dossiers_filtered_count, 1)
    assign(:archived_dossiers, [])
    assign(:dossiers_archived_filtered_count, 0)
  end

  subject { render }

  context 'when instructeur with filter' do
    before do
      assign(:a_suivre_dossiers, [1])
      assign(:dossiers_a_suivre_filtered_count, 0)
    end

    it { is_expected.to include('0 dossiers correspondants aux filters acturels.') }
    it { is_expected.to include('1 dossiers en tout.') }
  end

  context 'when instructeur without filter' do
    before do
      assign(:a_suivre_dossiers, [1])
      assign(:dossiers_a_suivre_filtered_count, 1)
    end

    it { is_expected.not_to include('0 dossiers correspondants aux filters acturels.') }
    it { is_expected.not_to include('1 dossiers en tout.') }
  end
end
