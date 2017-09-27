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
    page.should have_xpath("//th[contains(text(), 'Créé le')]")
    page.should have_xpath("//a[contains(text(), '#{new_unfollow_dossier.created_at}')]")
  end

  scenario "should add be able to add custom type_de_champ column", js: true do
    add_column(type_de_champ.libelle)
    page.should have_xpath("//th[contains(text(), '#{type_de_champ.libelle}')]")
    page.should have_xpath("//a[contains(text(), '#{champ.value}')]")
    expect(page).to have_content(champ.value)
  end

  def add_column(column_name)
    find(:xpath, "//span[contains(text(), 'Personnaliser')]").click
    find("span.select2-container").click
    find(:xpath, "//li[text()='#{column_name}']").click
    click_button "Enregistrer"
  end
end
