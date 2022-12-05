describe 'BatchOperation a dossier:', js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:password) { 'demarches-simplifiees' }
  let(:instructeur) { create(:instructeur, password: password) }
  let(:procedure) { create(:simple_procedure, :published, instructeurs: [instructeur], administrateurs: [create(:administrateur)]) }

  context 'with an instructeur' do
    scenario 'create a BatchOperation' do
      dossier_1 = create(:dossier, :accepte, procedure: procedure)
      dossier_2 = create(:dossier, :accepte, procedure: procedure)
      dossier_3 = create(:dossier, :accepte, procedure: procedure)
      log_in(instructeur.email, password)
      visit instructeur_procedure_path(procedure, statut: 'traites')

      # check a11y with enabled checkbox
      expect(page).to be_axe_clean
      # ensure button is disabled by default
      expect(page).to have_button("Archiver les dossiers sélectionnés", disabled: true)

      checkbox_id = dom_id(BatchOperation.new, "checkbox_#{dossier_1.id}")
      # batch one dossier
      check(checkbox_id)
      expect(page).to have_button("Archiver les dossiers sélectionnés")

      # ensure batch is created
      expect { click_on "Archiver les dossiers sélectionnés" }
        .to change { BatchOperation.count }
        .from(0).to(1)

      # ensure batched dossier is disabled
      expect(page).to have_selector("##{checkbox_id}[disabled]")
      # check a11y with disabled checkbox
      expect(page).to be_axe_clean

      # ensure alert is present
      expect(page).to have_content("Information : Une action de masse est en cours")
      expect(page).to have_content("1 dossier sera archivé")

      # ensure jobs are queued
      perform_enqueued_jobs(only: [BatchOperationEnqueueAllJob])
      expect { perform_enqueued_jobs(only: [BatchOperationProcessOneJob]) }
        .to change { dossier_1.reload.archived }
        .from(false).to(true)

      # ensure alert updates when jobs are run
      click_on "Recharger la page"
      expect(page).to have_content("L'action de masse est terminée")
      expect(page).to have_content("1 dossier a été archivé")

      # clean alert after reload
      visit instructeur_procedure_path(procedure, statut: 'traites')
      expect(page).not_to have_content("L'action de masse est terminée")

      # try checkall
      find("##{dom_id(BatchOperation.new, :checkbox_all)}").check
      [dossier_2, dossier_3].map do |dossier|
        dossier_checkbox_id = dom_id(BatchOperation.new, "checkbox_#{dossier.id}")
        expect(page).to have_selector("##{dossier_checkbox_id}:checked")
      end

      # submnit checkall
      expect { click_on "Archiver les dossiers sélectionnés" }
        .to change { BatchOperation.count }
        .from(1).to(2)

      expect(BatchOperation.last.dossiers).to match_array([dossier_2, dossier_3])
    end
  end

  def log_in(email, password, check_email: true)
    visit new_user_session_path
    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password, check_email)

    expect(page).to have_current_path(instructeur_procedures_path)
  end
end
