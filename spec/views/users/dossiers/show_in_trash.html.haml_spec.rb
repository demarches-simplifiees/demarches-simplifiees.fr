# frozen_string_literal: true

describe 'users/dossiers/show_in_trash', type: :view do
  let(:dossier) { create(:dossier, :hidden_by_user) }

  before do
    assign(:hidden_dossier, dossier)
    render
  end

  it 'shows trash message' do
    expect(rendered).to have_text("Le dossier n° #{dossier.id} a été mis à la corbeille")
    expect(rendered).to have_text('Consulter la corbeille')
  end

  it 'shows restore options' do
    expect(rendered).to have_text('restaurer')
    expect(rendered).to have_text('télécharger')
  end
end
