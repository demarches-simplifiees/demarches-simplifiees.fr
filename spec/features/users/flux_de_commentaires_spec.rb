require 'spec_helper'

feature 'users: flux de commentaires' do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :with_entreprise, user: user, state: Dossier.states.fetch(:en_construction)) }
  let(:dossier_id) { dossier.id }

  let(:champ1) { dossier.champs.first }
  let(:champ2) { create(:champ, dossier: dossier, type_de_champ: create(:type_de_champ, libelle: "subtitle")) }

  let!(:commentaire1) { create(:commentaire, dossier: dossier, champ: champ1) }
  let!(:commentaire2) { create(:commentaire, dossier: dossier, email: 'paul.chavard@beta.gouv.fr') }
  let!(:commentaire3) { create(:commentaire, dossier: dossier, champ: champ2) }
  let!(:commentaire4) { create(:commentaire, dossier: dossier, champ: champ1) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:new_dossier_details, false)
    login_as user, scope: :user
    visit users_dossier_recapitulatif_path(dossier)
  end

  scenario "seuls les commentaires généraux sont affichés" do
    comments = find(".commentaires")
    expect(comments).to have_selector(".content", count: 1)
    expect(comments).to have_content('paul.chavard')
    expect(comments).not_to have_content('paul.chavard@beta.gouv.fr')
  end
end
