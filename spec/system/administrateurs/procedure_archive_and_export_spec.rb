require 'system/administrateurs/procedure_spec_helper'

describe 'Creating a new procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let(:procedure) do
    create(:procedure, :with_service, :with_instructeur,
      aasm_state: :publiee,
      administrateurs: [administrateur],
      libelle: 'libellé de la procédure',
      path: 'libelle-de-la-procedure')
  end
  let!(:dossiers) do
    create(:dossier, :accepte, procedure: procedure)
  end

  before { login_as administrateur.user, scope: :user }

  scenario "download archive" do
    visit admin_procedure_path(id: procedure.id)

    # check button
    expect(page).to have_selector('#archive-procedure')
    click_on "Télécharger"

    # check page loading
    expect(page).to have_content("Archives")

    # check archive
    expect {
      page.first(".archive-table .button").click
    }.to have_enqueued_job(ArchiveCreationJob).with(procedure, an_instance_of(Archive), administrateur)
    expect(page).to have_content("Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre de quelques minutes a plusieurs heures. Vous recevrez un courriel lorsque le fichier sera disponible.")

    # check exports
    click_on "Télécharger tous les dossiers"

    expect {
      click_on "Demander un export au format .xlsx"
      expect(page).to have_content("Nous générons cet export. Veuillez revenir dans quelques minutes pour le télécharger.")
    }.to have_enqueued_job(ExportJob).with(an_instance_of(Export))
  end
end
