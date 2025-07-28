# frozen_string_literal: true

describe "procedure exports zip" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, instructeurs: [instructeur]) }
  let(:types_de_champ_public) { [{ type: :text }] }

  before do
    login_as(instructeur.user, scope: :user)
  end

  scenario "create an export_template zip", chome: true do
    visit instructeur_procedure_path(procedure)

    find("button", text: "Téléchargements").click

    click_on "Modèles d’export"

    click_on "Créer un modèle d’export zip"

    fill_in "Nom du modèle", with: "Mon modèle"
    expect(page).to have_content("Sélectionnez les fichiers que vous souhaitez exporter")
    check 'Pièces jointes à la messagerie'
    check 'Pièces jointes aux avis externes'
    check 'Justificatif de décision'
    click_on "Enregistrer"

    expect(page).to have_content("Modèles d’export")
    expect(page).not_to have_content("Vous n’avez pas le droit de créer un modèle d’export pour ce groupe")
  end
end
