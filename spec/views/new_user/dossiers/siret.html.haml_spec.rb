require 'spec_helper'

describe 'new_user/dossiers/siret.html.haml', type: :view do
  let(:dossier) { create(:dossier) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'affiche les informations de la démarche' do
    expect(rendered).to have_text(dossier.procedure.libelle)
  end

  it 'affiche le formulaire de SIRET' do
    expect(rendered).to have_field('Numéro SIRET')
  end

  it 'prépare le footer' do
    expect(footer).to have_selector('footer')
  end
end
