describe 'users/dossiers/dossier_actions.html.haml', type: :view do
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
  let(:user) { dossier.user }

  subject { render 'users/dossiers/dossier_actions.html.haml', dossier: dossier, current_user: user }

  it { is_expected.to have_link('Commencer un autre dossier', href: commencer_url(path: procedure.path)) }
  it { is_expected.to have_link('Supprimer le dossier', href: delete_dossier_dossier_path(dossier)) }
  it { is_expected.to have_link('Transférer le dossier', href: transferer_dossier_path(dossier)) }

  context 'when the dossier is termine' do
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    it { is_expected.to have_link('Supprimer le dossier') }
  end

  context 'when the procedure is closed' do
    let(:procedure) { create(:procedure, :closed) }
    it { is_expected.not_to have_link('Commencer un autre dossier') }
  end
end
