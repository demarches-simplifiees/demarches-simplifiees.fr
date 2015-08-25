require 'spec_helper'

describe 'recapitulatif/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise) }
  before do
    assign(:dossier, dossier.decorate)
    assign(:commentaires, dossier.commentaires)
    render
  end
  it { expect(rendered).to have_content("Contacter l'administration") }
  it { expect(rendered).to include(dossier.mailto.gsub('&','&amp;')) }
end
