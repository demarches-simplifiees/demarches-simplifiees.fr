require 'spec_helper'

describe 'dossiers/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise) }
  before do
    assign(:dossier, dossier)
    assign(:entreprise, dossier.entreprise.decorate)
    assign(:etablissement, dossier.etablissement)

    render
  end
  it 'have autorisation_donnees check box' do
    expect(rendered).to have_css('#dossier_autorisation_donnees')
  end
end