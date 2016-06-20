require 'spec_helper'

describe 'dossiers/show.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :with_entreprise, user: user) }

  before do
    assign(:facade, DossierFacades.new(dossier.id, user.email))

    render
  end

  it 'have autorisation_donnees check box' do
    expect(rendered).to have_css('#dossier_autorisation_donnees')
  end

  context "sur la page d'information d'un SIRET" do
    it 'Le formulaire envoie vers /users/dossiers/:dossier_id en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers'][method=post]")
    end

    it "la checkbox d'information est présente" do
      expect(rendered).to have_css('#dossier_autorisation_donnees')
    end

    it "le texte d'information des droits est correct" do
      expect(rendered).to have_content("J'autorise les décideurs publics à vérifier les informations de mon organisation auprès des administrations concernées. Ces informations resteront strictement confidentielles.")
    end

    it "les informations de l'entreprise sont présents" do
      expect(rendered).to have_content('Siret')
    end

    it 'le bouton "Etape suivante" est présent' do
      expect(rendered).to have_selector('#etape_suivante')
    end
  end
end
