describe 'instructeurs/procedures/_list.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:procedure2) { create(:procedure) }
  let!(:dossier) { create(:dossier, procedure: procedure) }

  context 'when instructeur with filter' do
    subject {
      render 'instructeurs/procedures/list.html.haml',
      dossiers_a_suivre_count_per_procedure: { procedure.id => 1, procedure2.id => 1 },
      dossiers_filtered_a_suivre_count_per_procedure: { procedure.id => 0, procedure2.id => 1 },
      followed_dossiers_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_followed_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_all_state_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_termines_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_termines_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_archived_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_archived_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      procedures: [procedure, procedure2],
      current_instructeur: current_instructeur
    }

    it { is_expected.to include('0 dossiers correspondants aux filters acturels.') }
    it { is_expected.to include('1 dossiers en tout.') }
  end

  context 'when instructeur without filter' do
    let(:procedure2) { create(:procedure) }

    subject {
      render 'instructeurs/procedures/list.html.haml',
      dossiers_a_suivre_count_per_procedure: { procedure.id => 1, procedure2.id => 1 },
      dossiers_filtered_a_suivre_count_per_procedure: { procedure.id => 1, procedure2.id => 1 },
      followed_dossiers_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_followed_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_all_state_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_termines_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_termines_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_archived_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      dossiers_filtered_archived_count_per_procedure: { procedure.id => 0, procedure2.id => 0 },
      procedures: [procedure, procedure2],
      current_instructeur: current_instructeur
    }

    it { is_expected.not_to include('0 dossiers correspondants aux filters acturels.') }
    it { is_expected.not_to include('1 dossiers en tout.') }
  end
end
