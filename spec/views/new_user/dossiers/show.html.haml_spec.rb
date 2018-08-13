require 'spec_helper'

describe 'new_user/dossiers/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_service, state: 'brouillon', procedure: create(:procedure)) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'affiche les informations du dossier' do
    expect(rendered).to have_text(dossier.procedure.libelle)
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
  end
end
