# frozen_string_literal: true

describe 'address champ', js: true do
  let(:password) { SECURE_PASSWORD }
  let!(:user) { create(:user, password: password) }
  let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :address, libelle: 'Adresse du domicile' }]) }
  let(:user_dossier) { user.dossiers.first }

  before do
    log_in(user, procedure)
    fill_individual
  end

  scenario "the BAN autocomplete is enabled by default" do
    expect(page).to have_selector('legend', text: 'Adresse du domicile')
    expect(page).to have_selector('.fr-input-group.address-ban input:enabled')
    expect(page).to have_unchecked_field("Je ne trouve pas mon adresse dans les suggestions")
    expect(page).not_to have_selector('.fr-input-group', text: 'Adresse du domicile', visible: true)
  end

  scenario "the user wants to fill an address that is not in the BAN" do
    find('label', text: 'Je ne trouve pas mon adresse dans les suggestions').click
    expect(page).to have_selector('.fr-input-group.address-ban input:disabled')
    expect(page).to have_selector('fieldset legend.fr-fieldset__legend', text: 'Adresse du domicile')
    expect(page).to have_select("Pays", selected: 'France')
    expect(page).to have_field("Numéro et nom de voie, ou lieu-dit")
    expect(page).to have_field("Ville ou commune")
  end

  scenario "the user wants to fill an international address" do
    find('label', text: 'Je ne trouve pas mon adresse dans les suggestions').click
    select "Suisse", from: "Pays"
    expect(page).to have_field("Numéro et nom de voie, ou lieu-dit")
    expect(page).to have_field("Ville")
    expect(page).to have_field("Code postal")
  end

  scenario "the user selects a foreign country and then France again." do
    find('label', text: 'Je ne trouve pas mon adresse dans les suggestions').click
    select "Suisse", from: "Pays"

    wait_until { user_dossier.reload.project_champs_public.first.value_json["country_code"] == "CH" }

    select "France", from: "Pays"
    expect(page).to have_select("Pays", selected: 'France')
    expect(page).to have_field("Numéro et nom de voie, ou lieu-dit")
    expect(page).to have_field("Ville ou commune")
  end

  scenario "the user wants to return on the BAN search" do
    find('label', text: 'Je ne trouve pas mon adresse dans les suggestions').click
    select "Suisse", from: "Pays"

    wait_until { user_dossier.reload.project_champs_public.first.value_json["country_code"] == "CH" }

    find('label', text: 'Je ne trouve pas mon adresse dans les suggestions').click
    expect(page).to have_selector('.fr-input-group.address-ban input:enabled')
    expect(page).not_to have_selector('.fr-input-group', text: 'Adresse du domicile', visible: true)
  end

  private

  def log_in(user, procedure)
    login_as user, scope: :user

    visit "/commencer/#{procedure.path}"
    click_on 'Commencer la démarche'

    expect(page).to have_content("Votre identité")
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def fill_individual
    fill_in('Prénom', with: 'prenom', visible: true)
    fill_in('Nom', with: 'Nom', visible: true)
    within "#identite-form" do
      click_on 'Continuer'
    end
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end
end
