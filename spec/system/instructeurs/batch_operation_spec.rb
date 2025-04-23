# frozen_string_literal: true

describe 'BatchOperation a dossier:', js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:password) { 'demarches-simplifiees' }
  let(:instructeur) { create(:instructeur, password: password) }
  let(:procedure) { create(:simple_procedure, :published, instructeurs: [instructeur], administrateurs: [administrateurs(:default_admin)]) }

  context 'with an instructeur' do
    scenario 'create a BatchOperation', chrome: true do
      dossier_1 = create(:dossier, :accepte, procedure: procedure)
      dossier_2 = create(:dossier, :accepte, procedure: procedure)
      dossier_3 = create(:dossier, :accepte, procedure: procedure)
      log_in(instructeur.email, password)

      # visit a page without batch operation and make sure there is no checkboxes in table
      visit instructeur_procedure_path(procedure, statut: 'tous')
      expect(page).not_to have_selector("#checkbox_all_batch_operation")
      expect(page).not_to have_selector("#checkbox_#{dossier_1.id}_batch_operation")

      visit instructeur_procedure_path(procedure, statut: 'traites')

      # check a11y with enabled checkbox
      expect(page).to be_axe_clean
      # ensure button is disabled by default
      expect(page).to have_button("Archiver les dossiers", disabled: true)

      checkbox_id = dom_id(BatchOperation.new, "checkbox_#{dossier_1.id}")
      # batch one dossier
      check(checkbox_id)
      expect(page).to have_button("Archiver les dossiers")

      # ensure batch is created

      accept_alert do
        click_on "Archiver les dossiers"
      end

      # ensure batched dossier is disabled
      expect(page).to have_selector("##{checkbox_id}[disabled]")
      # ensure Batch is created
      expect(BatchOperation.count).to eq(1)
      # check a11y with disabled checkbox
      expect(page).to be_axe_clean

      # ensure alert is present
      expect(page).to have_content("Information : Une action de masse est en cours")
      expect(page).to have_content("1 dossier est en cours de déplacement dans « à archiver »")

      # ensure jobs are queued
      perform_enqueued_jobs(only: [BatchOperationEnqueueAllJob])
      expect { perform_enqueued_jobs(only: [BatchOperationProcessOneJob]) }
        .to change { dossier_1.reload.archived }
        .from(false).to(true)

      # ensure alert updates when jobs are run
      click_on "Recharger la page"
      expect(page).to have_content("L’action de masse est terminée")
      expect(page).to have_content("1 dossier a été placé dans « à archiver »")

      # clean alert after reload
      visit instructeur_procedure_path(procedure, statut: 'traites')
      expect(page).not_to have_content("L’action de masse est terminée")

      # try checkall
      find("##{dom_id(BatchOperation.new, :checkbox_all)}").check

      # multiple select notice don't appear if all the dossiers are on the same page
      expect(page).to have_selector('#js_batch_select_more', visible: false)

      [dossier_2, dossier_3].map do |dossier|
        dossier_checkbox_id = dom_id(BatchOperation.new, "checkbox_#{dossier.id}")
        expect(page).to have_selector("##{dossier_checkbox_id}:checked")
      end

      # submit checkall
      accept_alert do
        click_on "Archiver les dossiers"
      end

      # reload
      visit instructeur_procedure_path(procedure, statut: 'traites')

      expect(BatchOperation.count).to eq(2)
      expect(BatchOperation.last.dossiers).to match_array([dossier_2, dossier_3])
    end

    scenario 'create a BatchOperation with more dossiers than pagination' do
      stub_const "Instructeurs::ProceduresController::ITEMS_PER_PAGE", 2
      dossier_1 = create(:dossier, :en_instruction, procedure: procedure)
      dossier_2 = create(:dossier, :en_instruction, procedure: procedure)
      dossier_3 = create(:dossier, :en_instruction, procedure: procedure)
      log_in(instructeur.email, password)

      visit instructeur_procedure_path(procedure, statut: 'a-suivre')

      expect(page).to have_content("1 - 2 sur 3 dossiers")

      # click on check_all make the notice appear
      find("##{dom_id(BatchOperation.new, :checkbox_all)}").check
      expect(page).to have_selector('#js_batch_select_more')
      expect(page).to have_content('Les 2 dossiers de cette page sont sélectionnés. Sélectionner la totalité des 3 dossiers.')

      # click on selection link fill checkbox value with dossier_ids
      click_on("Sélectionner la totalité des 3 dossiers")
      expect(page).to have_content('3 dossiers sont sélectionnés. Effacer la sélection ')
      expect(find_field("batch_operation[dossier_ids][]", type: :hidden).value).to eq "#{dossier_3.id},#{dossier_2.id},#{dossier_1.id}"

      # click on delete link empty checkbox value and hide notice
      click_on("Effacer la sélection")
      expect(page).to have_selector('#js_batch_select_more', visible: false)
      expect(page).to have_button("Suivre les dossiers", disabled: true)
      expect(find_field("batch_operation[dossier_ids][]", type: :hidden).value).to eq ""

      # click on check_all + notice link and submit
      find("##{dom_id(BatchOperation.new, :checkbox_all)}").check
      click_on("Sélectionner la totalité des 3 dossiers")

      accept_alert do
        click_on "Suivre les dossiers"
      end

      # reload
      visit instructeur_procedure_path(procedure, statut: 'a-suivre')

      expect(BatchOperation.count).to eq(1)
      expect(BatchOperation.last.dossiers).to match_array([dossier_1, dossier_2, dossier_3])
    end

    scenario 'create a BatchOperation within the limit of selection' do
      stub_const "Instructeurs::ProceduresController::ITEMS_PER_PAGE", 2
      stub_const "Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT", 3
      dossier_1 = create(:dossier, :en_instruction, procedure: procedure)
      dossier_2 = create(:dossier, :en_instruction, procedure: procedure)
      dossier_3 = create(:dossier, :en_instruction, procedure: procedure)
      dossier_4 = create(:dossier, :en_instruction, procedure: procedure)
      log_in(instructeur.email, password)

      visit instructeur_procedure_path(procedure, statut: 'a-suivre')

      # click on check_all make the notice appear
      find("##{dom_id(BatchOperation.new, :checkbox_all)}").check
      expect(page).to have_selector('#js_batch_select_more')
      expect(page).to have_content('Les 2 dossiers de cette page sont sélectionnés. Sélectionner les 3 premiers dossiers sur les 4')

      # click on selection link fill checkbox value with dossier_ids
      click_on("Sélectionner les 3 premiers dossiers sur les 4")
      expect(page).to have_content('3 dossiers sont sélectionnés. Effacer la sélection')
      expect(find_field("batch_operation[dossier_ids][]", type: :hidden).value).to eq "#{dossier_4.id},#{dossier_3.id},#{dossier_2.id}"

      # create batch
      accept_alert do
        click_on "Suivre les dossiers"
      end

      # reload
      visit instructeur_procedure_path(procedure, statut: 'a-suivre')

      expect(BatchOperation.count).to eq(1)
      expect(BatchOperation.last.dossiers).to match_array([dossier_2, dossier_3, dossier_4])
    end
  end

  def log_in(email, password)
    visit new_user_session_path
    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password)

    expect(page).to have_current_path(instructeur_procedures_path)
  end
end
