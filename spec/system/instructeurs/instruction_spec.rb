describe 'Instructing a dossier:', js: true do
  include ActiveJob::TestHelper
  include Logic

  let(:password) { SECURE_PASSWORD }
  let!(:instructeur) { create(:instructeur, password: password) }

  let!(:procedure) { create(:procedure, :published, instructeurs: [instructeur], types_de_champ_private: [{ type: 'checkbox', libelle: 'Yes/No', stable_id: 99 }, { libelle: 'Nom', condition: ds_eq(champ_value(99), constant(true)) }]) }
  let!(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }
  context 'the instructeur is also a user' do
    scenario 'a instructeur can fill a dossier' do
      visit commencer_path(path: procedure.path)
      click_on 'J’ai déjà un compte'

      expect(page).to have_current_path new_user_session_path
      sign_in_with(instructeur.email, password, true)

      # connexion link erase user stored location
      # expect(page).to have_current_path(commencer_path(path: procedure.path))

      visit commencer_path(path: procedure.path)
      click_on 'Commencer la démarche'

      expect(page).to have_content('Identifier votre établissement')
      expect(page).to have_current_path(siret_dossier_path(procedure.reload.dossiers.last))
      expect(page).to have_content(procedure.libelle)
    end
  end

  scenario 'A instructeur can accept a dossier' do
    log_in(instructeur.email, password)

    expect(page).to have_current_path(instructeur_procedures_path)

    click_on procedure.libelle
    expect(page).to have_current_path(instructeur_procedure_path(procedure))

    click_on dossier.user.email
    expect(page).to have_current_path(instructeur_dossier_path(procedure, dossier))

    click_on 'Passer en instruction'

    expect(page).to have_text('Dossier passé en instruction.')
    expect(page).to have_text('Instruire le dossier')
    expect(page).to have_selector('.fr-badge', text: 'en instruction')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction))

    click_on 'Instruire le dossier'

    within('.instruction-button') do
      click_on 'Accepter'
    end

    within('.accept.motivation') do
      fill_in('dossier_motivation', with: 'a good reason')

      accept_confirm do
        click_on 'Valider la décision'
      end
    end

    expect(page).to have_text('Dossier traité avec succès.')
    expect(page).to have_button('Archiver le dossier')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
    expect(dossier.motivation).to eq('a good reason')

    click_on procedure.libelle
    click_on 'traité'
    expect(page).to have_button('Repasser en instruction')
    click_on 'Supprimer le dossier'
    click_on 'traité'
    expect(page).not_to have_button('Repasser en instruction')
  end

  scenario 'An instructeur can add anotations' do
    log_in(instructeur.email, password)

    visit instructeur_dossier_path(procedure, dossier)
    click_on 'Annotations privées'

    expect(page).not_to have_field 'Nom', visible: true
    check 'Yes/No', allow_label_click: true
    expect(page).to have_field 'Nom'
    fill_in 'Nom', with: 'John Doe'
    expect(page).to have_text 'Annotations enregistrées'
  end

  scenario 'An instructeur can destroy a dossier from view' do
    log_in(instructeur.email, password)

    dossier.passer_en_instruction(instructeur: instructeur)
    dossier.accepter!(instructeur: instructeur)
    visit instructeur_dossier_path(procedure, dossier)
    click_on 'Supprimer le dossier'
  end

  scenario 'A instructeur can follow/unfollow a dossier' do
    log_in(instructeur.email, password)

    click_on procedure.libelle
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    dossier_present?(dossier.id, 'en construction')

    click_on 'Suivre le dossier'
    expect(page).to have_current_path(instructeur_procedure_path(procedure))
    test_statut_bar(suivi: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')

    click_on 'suivi'
    expect(page).to have_current_path(instructeur_procedure_path(procedure, statut: 'suivis'))
    dossier_present?(dossier.id, 'en construction')

    click_on 'Ne plus suivre'
    expect(page).to have_current_path(instructeur_procedure_path(procedure, statut: 'suivis'))
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')
  end

  scenario 'A instructeur can request an export' do
    assert_performed_jobs 1 do
      log_in(instructeur.email, password)
    end

    click_on procedure.libelle
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)

    click_on "Télécharger un dossier"
    within(:css, '.dossiers-export') do
      click_on "Demander un export au format .csv"
    end

    expect(page).to have_text('Nous générons cet export.')

    click_on "voir les exports"
    expect(page).to have_text("Export .csv d’un dossier « à suivre » demandé il y a moins d'une minute")
    expect(page).to have_text("En préparation")

    assert_performed_jobs 1 do
      perform_enqueued_jobs(only: ExportJob)
    end

    page.driver.browser.navigate.refresh
    expect(page).to have_text('Télécharger l’export')
  end

  scenario 'A instructeur can see the personnes impliquées' do
    instructeur2 = create(:instructeur, password: password)

    log_in(instructeur.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Avis externes'
    expect(page).to have_current_path(avis_instructeur_dossier_path(procedure, dossier))
    within('.fr-sidemenu') { click_on 'Demander un avis' }
    expect(page).to have_current_path(avis_new_instructeur_dossier_path(procedure, dossier))

    expert_email_formated = "[\"expert@tps.com\"]"
    expert_email = 'expert@tps.com'
    ask_confidential_avis(expert_email_formated, 'a good introduction')

    expert_email_formated = "[\"#{instructeur2.email}\"]"
    expert_email = instructeur2.email
    ask_confidential_avis(expert_email_formated, 'a good introduction')

    click_on 'Personnes impliquées'
    expect(page).to have_text(expert_email)
    expect(page).to have_text(instructeur2.email)
  end

  scenario 'A instructeur can send a dossier to several instructeurs' do
    instructeur_2 = create(:instructeur)
    instructeur_3 = create(:instructeur)
    procedure.defaut_groupe_instructeur.instructeurs << [instructeur_2, instructeur_3]

    send_dossier = double()
    expect(InstructeurMailer).to receive(:send_dossier).and_return(send_dossier).twice
    expect(send_dossier).to receive(:deliver_later).twice

    log_in(instructeur.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Personnes impliquées'

    select_combobox('Emails', instructeur_2.email, instructeur_2.email, check: false)
    select_combobox('Emails', instructeur_3.email, instructeur_3.email, check: false)

    click_on 'Envoyer'

    expect(page).to have_text("Dossier envoyé")
  end

  context 'A instructeur can ask for an Archive' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative }], instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    before do
      log_in(instructeur.email, password)
      visit instructeur_archives_path(procedure)
    end
    scenario 'download' do
      expect {
        page.first(".archive-table .fr-btn").click
      }.to have_enqueued_job(ArchiveCreationJob).with(procedure, an_instance_of(Archive), instructeur)
      expect(Archive.first.month).not_to be_nil
    end
  end
  context 'with dossiers having attached files', js: true do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative }], instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let(:champ) { dossier.champs_public.first }
    let(:path) { 'spec/fixtures/files/piece_justificative_0.pdf' }
    let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }

    before do
      dossier.passer_en_instruction!(instructeur: instructeur)
      champ.piece_justificative_file
        .attach(io: File.open(path),
                filename: "piece_justificative_0.pdf",
                content_type: "application/pdf",
                metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE })

      log_in(instructeur.email, password)
      visit instructeur_dossier_path(procedure, dossier)
    end

    scenario 'A instructeur can download an archive containing a single attachment' do
      find(:css, '[aria-controls=print-pj-menu]').click
      click_on 'Télécharger le dossier et toutes ses pièces jointes'
      # For some reason, clicking the download link does not trigger the download in the headless browser ;
      # So we need to go to the download link directly
      visit telecharger_pjs_instructeur_dossier_path(procedure, dossier)

      DownloadHelpers.wait_for_download
      files = ZipTricks::FileReader.read_zip_structure(io: File.open(DownloadHelpers.download))

      expect(DownloadHelpers.download).to include "dossier-#{dossier.id}.zip"
      expect(files.size).to be 2
      expect(files[0].filename.include?('export')).to be_truthy
      expect(files[1].filename.include?('piece_justificative_0')).to be_truthy
      expect(files[1].uncompressed_size).to be File.size(path)
    end

    scenario 'A instructeur can download an archive containing several identical attachments' do
      commentaire
        .piece_jointe
        .attach(io: File.open(path),
                filename: "piece_justificative_0.pdf",
                content_type: "application/pdf",
                metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE })

      visit telecharger_pjs_instructeur_dossier_path(procedure, dossier)
      DownloadHelpers.wait_for_download
      files = ZipTricks::FileReader.read_zip_structure(io: File.open(DownloadHelpers.download))

      expect(DownloadHelpers.download).to include "dossier-#{dossier.id}.zip"
      expect(files.size).to be 3
      expect(files[0].filename.include?('export')).to be_truthy
      expect(files[1].filename.include?('piece_justificative_0')).to be_truthy
      expect(files[2].filename.include?('piece_justificative_0')).to be_truthy
      expect(files[1].filename).not_to eq files[2].filename
      expect(files[1].uncompressed_size).to be File.size(path)
      expect(files[2].uncompressed_size).to be File.size(path)
    end

    before { DownloadHelpers.clear_downloads }
    after { DownloadHelpers.clear_downloads }
  end

  def log_in(email, password, check_email: true)
    visit new_user_session_path
    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password, check_email)

    expect(page).to have_current_path(instructeur_procedures_path)
  end

  def log_out
    click_on 'Se déconnecter'
  end

  def ask_confidential_avis(to, introduction)
    page.execute_script("document.querySelector('#avis_emails').value = '#{to}'")
    fill_in 'avis_introduction', with: introduction
    select 'confidentiel', from: 'avis_confidentiel'
    within('form#new_avis') { click_on 'Demander un avis' }
    click_on 'Demander un avis'
  end

  def test_statut_bar(a_suivre: 0, suivi: 0, traite: 0, tous_les_dossiers: 0, archive: 0)
    texts = [
      "#{a_suivre} à suivre",
      "#{suivi} suivi",
      "#{traite} traité",
      "#{tous_les_dossiers} au total",
      "#{archive} archivé"
    ]

    texts.each { |text| expect(page).to have_text(text) }
  end

  def dossier_present?(id, statut)
    within(:css, '.dossiers-table') do
      expect(page).to have_text(id)
      expect(page).to have_text(statut)
    end
  end
end
