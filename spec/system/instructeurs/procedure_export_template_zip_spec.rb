# frozen_string_literal: true

describe "procedure exports zip" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, instructeurs: [instructeur]) }
  let(:types_de_champ_public) { [{ type: :text }] }
  before { login_as(instructeur.user, scope: :user) }

  scenario "create an export_template zip", chome: true do
    visit instructeur_procedure_path(procedure)

    find("button", text: "Téléchargements").click

    click_on "Liste des exports"

    click_on "Modèles d'export"

    click_on "Créer un modèle d'export zip"

    fill_in "Nom du modèle", with: "Mon modèle"
    expect(page).to have_content("Sélectionnez les fichiers que vous souhaitez exporter")
    click_on "Enregistrer"

    find("#tabpanel-export-templates", wait: 5, visible: true)
    find("#tabpanel-export-templates").click

    within 'table' do
      expect(page).to have_content('Mon modèle')
    end
  end
end
