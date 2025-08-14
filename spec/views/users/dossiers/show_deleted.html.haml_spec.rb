# frozen_string_literal: true

describe 'users/dossiers/show_deleted', type: :view do
  let(:deleted_dossier) { create(:deleted_dossier, dossier_id: 123) }

  before do
    assign(:deleted_dossier, deleted_dossier)
    render
  end

  it 'shows deletion message' do
    expect(rendered).to have_text('Le dossier n° 123 a été supprimé')
    expect(rendered).to have_text('Vous ne pouvez plus récupérer ce dossier')
  end

  it 'shows deletion reasons' do
    expect(rendered).to have_text('Il a été mis à la corbeille à votre demande')
    expect(rendered).to have_text('Il a été supprimé car son délai maximal')
  end
end
