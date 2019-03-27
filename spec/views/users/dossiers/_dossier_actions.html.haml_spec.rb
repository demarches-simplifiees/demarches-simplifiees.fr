describe 'users/dossiers/dossier_actions.html.haml', type: :view do
  let(:procedure) { create(:procedure, :published, expects_multiple_submissions: true) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

  subject { render 'users/dossiers/dossier_actions.html.haml', dossier: dossier }

  it { is_expected.to have_link('Commencer un autre dossier', href: commencer_url(path: procedure.path)) }
  it { is_expected.to have_link('Supprimer le dossier', href: ask_deletion_dossier_path(dossier)) }

  context 'when the dossier cannot be deleted' do
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    it { is_expected.not_to have_link('Supprimer le dossier') }
  end

  context 'when the procedure doesn’t expect multiple submissions' do
    let(:procedure) { create(:procedure, :published, expects_multiple_submissions: false) }
    it { is_expected.not_to have_link('Commencer un autre dossier') }
  end

  context 'when the procedure is closed' do
    let(:procedure) { create(:procedure, :archived, expects_multiple_submissions: true) }
    it { is_expected.not_to have_link('Commencer un autre dossier') }
  end

  context 'when there are no actions to display' do
    let(:procedure) { create(:procedure, :published, expects_multiple_submissions: false) }
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

    it 'doesn’t render the menu at all' do
      expect(subject).not_to have_selector('.dropdown')
    end
  end
end
