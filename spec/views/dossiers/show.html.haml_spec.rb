require 'spec_helper'

describe 'dossiers/show.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :with_entreprise, user: user) }

  before do
    assign(:facade, DossierFacades.new(dossier.id, user.email))

    render
  end

  context "sur la page d'information d'un SIRET" do
    it 'Le formulaire envoie vers /users/dossiers/:dossier_id en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers'][method=post]")
    end

    it "les informations de l'entreprise sont présents" do
      expect(rendered).to have_content('Siret')
    end

    it 'le bouton "Etape suivante" est présent' do
      expect(rendered).to have_selector('#etape_suivante')
    end
  end
end
