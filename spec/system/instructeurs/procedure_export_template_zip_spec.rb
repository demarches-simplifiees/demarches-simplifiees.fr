# frozen_string_literal: true

describe "procedure exports zip" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, instructeurs: [instructeur]) }
  let(:types_de_champ_public) { [{ type: :text }] }

  before do
    login_as(instructeur.user, scope: :user)
  end

  scenario "create an export_template zip", chrome: true do
    visit instructeur_procedure_path(procedure)

    find("button", text: "Téléchargements").click

    click_on "Modèles d’export"

    click_on "Créer un modèle d’export zip"

    fill_in "Nom du modèle", with: "Mon modèle"

    all('.fr-input-group .fr-tag').find { _1.text == 'SIREN' }.click

    expect(page).to have_content("Sélectionnez les fichiers que vous souhaitez exporter")
    custom_check("export_template_commentaires_attachments")
    custom_check("export_template_avis_attachments")
    custom_check("export_template_justificatif_motivation")
    click_on "Enregistrer"

    expect(page).to have_content("Modèles d’export")
    expect(page).not_to have_content("Vous n’avez pas le droit de créer un modèle d’export pour ce groupe")
    export_template = ExportTemplate.last
    dossier_folder_template = export_template.dossier_folder.template
    tiptap_tags = dossier_folder_template.dig(:content, 0, :content).filter { _1[:type] == "mention" }
    expect(tiptap_tags.map { _1[:attrs][:label] }).to include("SIREN")
  end
end
