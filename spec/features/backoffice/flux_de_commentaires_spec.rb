require 'spec_helper'

feature 'backoffice: flux de commentaires' do
  let(:procedure) { create(:procedure, :published) }
  let(:gestionnaire) { create(:gestionnaire) }
  let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction') }
  let(:dossier_id) { dossier.id }

  let(:champ1) { create(:champ, dossier: dossier, type_de_champ: create(:type_de_champ_public, libelle: "subtitle1")) }
  let(:champ2) { create(:champ, dossier: dossier, type_de_champ: create(:type_de_champ_public, libelle: "subtitle2")) }

  let!(:commentaire1) { create(:commentaire, dossier: dossier, champ: champ1) }
  let!(:commentaire2) { create(:commentaire, dossier: dossier) }
  let!(:commentaire3) { create(:commentaire, dossier: dossier, champ: champ2) }
  let!(:commentaire4) { create(:commentaire, dossier: dossier, champ: champ1) }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    login_as gestionnaire, scope: :gestionnaire
    visit backoffice_dossier_path(dossier)
  end

  scenario "seuls les commentaires généraux sont affichés" do
    comments = find(".commentaires")
    expect(comments).to have_selector(".content", count: 1)
  end
end
