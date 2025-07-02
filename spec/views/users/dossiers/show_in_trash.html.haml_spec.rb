# frozen_string_literal: true

describe 'users/dossiers/show_in_trash', type: :view do
  let(:procedure) { create(:procedure, :published, libelle: 'Test Procedure') }
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :en_construction, user: user, procedure: procedure) }

  before do
    dossier.hide_and_keep_track!(user, :user_request)

    sign_in user
    assign(:hidden_dossier, dossier)
  end

  subject! { render }

  it 'renders the dossier in trash page' do
    expect(rendered).to have_text("Le dossier n° #{dossier.id} a été mis à la corbeille")
    expect(rendered).to have_text('Consulter la corbeille')
  end

  it 'includes the correct card structure' do
    expect(rendered).to have_css('.fr-card.fr-card--no-border')
  end

  it 'displays the dossier number' do
    expect(rendered).to have_text(dossier.id.to_s)
  end

  it 'shows information about restoring or downloading' do
    expect(rendered).to have_text('restaurer')
    expect(rendered).to have_text('télécharger')
  end

  it 'has a link to the trash page' do
    expect(rendered).to have_link('Consulter la corbeille', href: dossiers_path(statut: 'dossiers-supprimes'))
  end

  it 'displays the explanation text' do
    expect(rendered).to have_text('Vous pouvez retrouver ce dossier depuis l\'onglet corbeille')
    expect(rendered).to have_text('Si ce dossier a été mis à la corbeille à votre demande')
    expect(rendered).to have_text('Si ce dossier a été mis à la corbeille automatiquement')
  end

  context 'when dossier has been automatically hidden' do
    before do
      # Simulate automatic hiding
      dossier.update(hidden_by_reason: :not_modified_for_a_long_time)
      assign(:hidden_dossier, dossier.reload)
    end

    subject! { render }

    it 'shows automatic deletion message' do
      expect(rendered).to have_text('Si ce dossier a été mis à la corbeille automatiquement')
    end
  end
end
