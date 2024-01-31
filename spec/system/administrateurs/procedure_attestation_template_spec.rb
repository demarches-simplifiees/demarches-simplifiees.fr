require 'system/administrateurs/procedure_spec_helper'

describe 'As an administrateur, I want to manage the procedure’s attestation', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let(:procedure) do
    create(:procedure, :with_service, :with_instructeur, :with_zone,
      aasm_state: :brouillon,
      administrateurs: [administrateur],
      libelle: 'libellé de la procédure',
      path: 'libelle-de-la-procedure')
  end
  before { login_as(administrateur.user, scope: :user) }

  def find_attestation_card(with_nested_selector: nil)
    full_selector = [
      "a[href=\"#{edit_admin_procedure_attestation_template_path(procedure)}\"]",
      with_nested_selector
    ].compact.join(" ")
    page.find(full_selector)
  end

  context 'Enable, publish, Disable' do
    scenario do
      visit admin_procedure_path(procedure)
      # start with no attestation
      expect(page).to have_content('Désactivée')
      find_attestation_card(with_nested_selector: ".fr-badge")

      expect(page).not_to have_content("Nouvel éditeur d’attestation")

      # now process to enable attestation
      find_attestation_card.click
      fill_in "Titre de l’attestation", with: 'BOOM'
      fill_in "Contenu de l’attestation", with: 'BOOM'
      find('.toggle-switch-control').click
      click_on 'Enregistrer'

      page.find(".alert-success", text: "Le modèle de l’attestation a bien été enregistré")

      # check attestation
      visit admin_procedure_path(procedure)
      expect(page).to have_content('Activée')
      find_attestation_card(with_nested_selector: ".fr-badge--success")

      # publish procedure
      # click CTA for publication screen
      click_on("Publier")
      # validate publication
      within('form') { click_on 'Publier' }
      click_on("Revenir à la page de la démarche")

      # now process to disable attestation
      find_attestation_card.click
      find('.toggle-switch-control').click
      click_on 'Enregistrer'
      page.find(".alert-success", text: "Le modèle de l’attestation a bien été modifié")

      # check attestation is now disabled
      visit admin_procedure_path(procedure)
      expect(page).to have_content('Désactivée')
      find_attestation_card(with_nested_selector: ".fr-badge")
    end
  end

  context 'Update attestation v2' do
    before { Flipper.enable(:attestation_v2) }

    scenario do
      visit admin_procedure_path(procedure)
      find_attestation_card(with_nested_selector: ".fr-badge")

      find_attestation_card.click
      within(".fr-alert", text: /Nouvel éditeur/) do
        find("a").click
      end

      expect(procedure.reload.attestation_template_v2).to be_nil

      expect(page).to have_css("label", text: "Logo additionnel")

      fill_in "Intitulé de votre institution", with: "System Test"
      fill_in "Intitulé de la direction", with: "The boss"

      attestation = nil
      wait_until {
        attestation = procedure.reload.attestation_template_v2
        attestation.present?
      }
      expect(attestation.label_logo).to eq("System Test")
      expect(attestation.activated?).to be_falsey

      click_on "date de décision"

      # TODO find a way to fill in tiptap

      attach_file('Tampon ou signature', Rails.root + 'spec/fixtures/files/white.png')
      wait_until { attestation.reload.signature.attached? }

      fill_in "Contenu du pied de page", with: "Footer"

      wait_until {
        body = JSON.parse(attestation.reload.tiptap_body)
        first_content = body.dig("content").first&.dig("content")&.first&.dig("content")&.first&.dig("content")

        first_content == [
          { "type" => "mention", "attrs" => { "id" => "dossier_processed_at", "label" => "date de décision" } }, # added by click above
          { "type" => "text", "text" => " " },
          { "type" => "mention", "attrs" => { "id" => "dossier_service_name", "label" => "nom du service" } } # defaut initial content
        ]
      }

      find("label", text: /à la charte de l’état/).click

      expect(page).not_to have_css("label", text: "Logo additionnel", visible: true)
      expect(page).not_to have_css("label", text: "Intitulé du logo", visible: true)

      attach_file('Logo', Rails.root + 'spec/fixtures/files/black.png')

      wait_until {
        attestation.reload.logo.attached? && attestation.signature.attached? && !attestation.official_layout?
      }

      # footer is rows-limited
      fill_in "Contenu du pied de page", with: ["line1", "line2", "line3", "line4"].join("\n")
      expect(page).to have_field("Contenu du pied de page", with: "line1\nline2\nline3line4")
    end
  end
end
