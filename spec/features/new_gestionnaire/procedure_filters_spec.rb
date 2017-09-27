require "spec_helper"

feature "procedure filters" do
  let(:procedure) { create(:procedure, :published, :with_type_de_champ) }
  let(:gestionnaire) { create(:gestionnaire, procedures: [procedure]) }
  let!(:type_de_champ) { procedure.types_de_champ.first }
  let!(:new_unfollow_dossier) { create(:dossier, procedure: procedure, state: "received") }
  let(:champ) { Champ.find_by(type_de_champ_id: type_de_champ.id) }

  before do
    champ.update_attributes(value: "Mon champ rempli")
    login_as gestionnaire, scope: :gestionnaire
    visit procedure_path(procedure)
  end

  scenario "should display demandeur by default" do
    expect(page).to have_content("Demandeur")
    expect(page).to have_content(new_unfollow_dossier.user.email)
  end

  scenario "should add be able to add created_at column", js: true do
    add_column("Créé le")
    within ".dossiers-table" do
      expect(page).to have_link("Créé le")
      expect(page).to have_link(new_unfollow_dossier.created_at)
    end
  end

  scenario "should add be able to add and remove custom type_de_champ column", js: true do
    add_column(type_de_champ.libelle)
    within ".dossiers-table" do
      expect(page).to have_link(type_de_champ.libelle)
      expect(page).to have_link(champ.value)
    end

    remove_column(type_de_champ.libelle)
    within ".dossiers-table" do
      expect(page).not_to have_link(type_de_champ.libelle)
      expect(page).not_to have_link(champ.value)
    end
  end

  def add_column(column_name)
    find(:xpath, "//span[contains(text(), 'Personnaliser')]").click
    find("span.select2-container").click
    find(:xpath, "//li[text()='#{column_name}']").click
    click_button "Enregistrer"
  end

  def remove_column(column_name)
    find(:xpath, "//span[contains(text(), 'Personnaliser')]").click
    find(:xpath, "//li[contains(@title, '#{column_name}')]/span[contains(text(), '×')]").click
    find(:xpath, "//span[contains(text(), 'Personnaliser')]//span[contains(@class, 'select2-container')]").click
    click_button "Enregistrer"
  end
end
