require 'spec_helper'

describe 'users/description/_pieces_justificatives.html.haml', type: :view do
  let!(:procedure) { create(:procedure) }
  let!(:tpj1) { create(:type_de_piece_justificative,
    procedure: procedure,
    libelle: "Première pièce jointe",
    description: "Première description",
    order_place: 1,
    mandatory: true
  )}
  let!(:tpj2) { create(:type_de_piece_justificative,
    procedure: procedure,
    libelle: "Seconde pièce jointe",
    description: "Seconde description",
    order_place: 2,
    lien_demarche: "https://www.google.fr"
  )}
  let!(:dossier) { create(:dossier, :procedure => procedure) }

  before do
    render 'users/description/pieces_justificatives.html.haml', dossier: dossier
  end

  it 'should render two PJ with their title, mandatory status and description' do
    expect(rendered).to include("Première pièce jointe *")
    expect(rendered).to include("Seconde pièce jointe")
    expect(rendered.index("Première pièce jointe")).to be < rendered.index("Seconde pièce jointe")

    expect(rendered).to include("Première description")
    expect(rendered).to include("Seconde description")

    expect(rendered).to have_selector("input[type=file]", count: 2)
  end
end
