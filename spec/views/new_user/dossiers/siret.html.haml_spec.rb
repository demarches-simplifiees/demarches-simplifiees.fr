require 'spec_helper'

describe 'new_user/dossiers/siret.html.haml', type: :view do
  let(:dossier) { create(:dossier) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'affiche le formulaire de SIRET' do
    expect(rendered).to have_field('Numéro TAHITI')
  end
end
