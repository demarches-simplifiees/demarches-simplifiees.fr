require 'system/administrateurs/procedure_spec_helper'

describe 'As an administrateur, I want to manage the procedure’s attestation', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let(:procedure) do
    create(:procedure, :with_service, :with_instructeur,
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
      find_attestation_card(with_nested_selector: ".icon.clock")

      # now process to enable attestation
      find_attestation_card.click
      fill_in "Titre de l’attestation", with: 'BOOM'
      fill_in "Contenu de l’attestation", with: 'BOOM'
      find('.toggle-switch-control').click
      click_on 'Enregistrer'

      page.find(".alert-success", text: "Le modèle de l’attestation a bien été enregistré")

      # check attestation
      visit admin_procedure_path(procedure)
      find_attestation_card(with_nested_selector: ".icon.accept")

      # publish procedure
      # click CTA for publication screen
      click_on("Publier")
      # validate publication
      click_on("Publier")

      # now process to disable attestation
      find_attestation_card.click
      find('.toggle-switch-control').click
      click_on 'Enregistrer'
      page.find(".alert-success", text: "Le modèle de l’attestation a bien été modifié")

      # check attestation is now disabled
      visit admin_procedure_path(procedure)
      find_attestation_card(with_nested_selector: ".icon.clock")
    end
  end
end
