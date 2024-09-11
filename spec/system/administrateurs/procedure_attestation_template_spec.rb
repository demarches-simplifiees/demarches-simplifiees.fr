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
    before do
      Flipper.enable(:attestation_v2)

      response = Typhoeus::Response.new(code: 200, body: 'Hello world')
      Typhoeus.stub(WEASYPRINT_URL).and_return(response)
    end

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
      expect(page).to have_content("Formulaire enregistré")

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

      fill_in "Contenu du pied de page", with: ["line1", "line2", "line3", "line4"].join("\n")
      # FIXME we should get line1\nline2\nline3line4 instead of line1\nline2\nline3\nline4 because row is set to 3
      expect(page).to have_field("Contenu du pied de page", with: "line1\nline2\nline3\nline4")

      click_on "Publier"
      expect(attestation.reload).to be_published
      expect(page).to have_text("L’attestation a été publiée")

      fill_in "Intitulé de la direction", with: "plop"
      click_on "Publier les modifications"
      expect(procedure.reload.attestation_template.label_direction).to eq("plop")
      expect(page).to have_text(/La nouvelle version de l’attestation/)
    end

    context "tag in error" do
      before do
        tdc = procedure.active_revision.add_type_de_champ(type_champ: :integer_number, libelle: 'age')
        procedure.publish_revision!

        attestation = procedure.build_attestation_template_v2(json_body: AttestationTemplate::TIPTAP_BODY_DEFAULT, label_logo: "test")
        attestation.json_body["content"] << { type: :mention, attrs: { id: "tdc#{tdc.stable_id}", label: tdc.libelle } }
        attestation.save!

        procedure.draft_revision.remove_type_de_champ(tdc)
      end

      scenario do
        visit edit_admin_procedure_attestation_template_v2_path(procedure)
        expect(page).to have_content("Le champ « Contenu de l’attestation » contient la balise \"age\"")

        click_on "date de décision"

        expect(page).to have_content("Formulaire en erreur")
        expect(page).to have_content("Le champ « Contenu de l’attestation » contient la balise \"age\"")

        page.execute_script("document.getElementById('attestation_template_tiptap_body').type = 'text'")
        fill_in "attestation_template[tiptap_body]", with: AttestationTemplate::TIPTAP_BODY_DEFAULT.to_json

        expect(page).to have_content("Formulaire enregistré")
        expect(page).not_to have_content("Formulaire en erreur")
        expect(page).not_to have_content("Le champ « Contenu de l’attestation » contient la balise \"age\"")
      end
    end
  end
end
