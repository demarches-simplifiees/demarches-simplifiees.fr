describe 'instructeurs/procedures/_synthese.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let!(:dossier) { create(:dossier, procedure: procedure) }

  subject {
    render 'instructeurs/procedures/synthese.html.haml',
    all_dossiers_counts: {
      'à suivre': 0,
      'suivi': 0,
      'traité': 1,
      'dossier': 1,
      'archivé': 0
    }
  }

  context 'when instructeur has 1 procedure and has 1 dossier' do
    it { is_expected.to have_text('Synthèse des dossiers') }
    it { is_expected.to have_css('.synthese') }
    it { is_expected.to have_text('suivi') }
    it { is_expected.to have_text('traité') }
    it { is_expected.to have_text('dossier') }
    it { is_expected.to have_text('archivé') }
  end
end
