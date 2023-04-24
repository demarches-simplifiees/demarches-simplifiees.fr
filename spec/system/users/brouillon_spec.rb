describe 'The user' do
  let(:password) { 'my-s3cure-p4ssword' }
  let!(:user) { create(:user, password: password) }

  let!(:procedure) { create(:procedure, :published, :for_individual, :with_all_champs_mandatory) }
  let(:user_dossier) { user.dossiers.first }
  let!(:dossier_to_link) { create(:dossier) }

  scenario 'fill a dossier', js: true do
    log_in(user, procedure)

    fill_individual

    # fill data
    fill_in('text *', with: 'super texte')
    fill_in('textarea', with: 'super textarea')
    fill_in('date *', with: '12-12-2012')
    fill_in('datetime', with: Time.zone.parse('2023-01-06T07:05'))
    find("input[type=datetime-local]").send_keys(:arrow_up).send_keys(:arrow_down) # triggers onChange
    fill_in('number', with: '42')
    fill_in('decimal_number', with: '17')
    fill_in('integer_number', with: '12')
    scroll_to(find_field('checkbox'), align: :center)
    check('checkbox')
    choose('Madame')
    fill_in('email', with: 'loulou@yopmail.com')
    fill_in('phone', with: '0123456789')
    scroll_to(find_field('Non'), align: :center)
    choose('Non')
    choose('val2')
    check('val1')
    check('val3')
    select('bravo', from: form_id_for('simple_choice_drop_down_list_long'))
    select('alpha', from: form_id_for('multiple_choice_drop_down_list_long'))
    select('charly', from: form_id_for('multiple_choice_drop_down_list_long'))

    select('Australie', from: form_id_for('pays'))
    select('Martinique', from: form_id_for('regions'))
    select('02 – Aisne', from: form_id_for('departements'))
    fill_in('Renseignez le code postal puis sélectionnez la commune dans la liste', with: '60400')
    select('Brétigny (60400)', from: form_id_for('communes'))

    fill_in('dossier_link', with: '123')
    find('.editable-champ-piece_justificative input[type=file]').attach_file(Rails.root + 'spec/fixtures/files/file.pdf')

    expect(page).to have_css('span', text: 'Votre brouillon est automatiquement enregistré', visible: true)
    wait_for_autosave

    # check data on the dossier
    expect(user_dossier.brouillon?).to be true
    expect(champ_value_for('text')).to eq('super texte')
    expect(champ_value_for('textarea')).to eq('super textarea')
    expect(champ_value_for('date')).to eq('2012-12-12')
    expect(champ_value_for('datetime')).to eq('2023-01-06T07:05:00+01:00')
    expect(champ_value_for('number')).to eq('42')
    expect(champ_value_for('decimal_number')).to eq('17')
    expect(champ_value_for('integer_number')).to eq('12')
    expect(champ_value_for('checkbox')).to eq('true')
    expect(champ_value_for('civilite')).to eq('Mme')
    expect(champ_value_for('email')).to eq('loulou@yopmail.com')
    expect(champ_value_for('phone')).to eq('0123456789')
    expect(champ_value_for('yes_no')).to eq('false')
    expect(champ_value_for('simple_drop_down_list')).to eq('val2')
    expect(champ_value_for('simple_choice_drop_down_list_long')).to eq('bravo')
    expect(JSON.parse(champ_value_for('multiple_choice_drop_down_list_long'))).to match(['alpha', 'charly'])
    expect(JSON.parse(champ_value_for('multiple_drop_down_list'))).to match(['val1', 'val3'])
    expect(champ_value_for('pays')).to eq('Australie')
    expect(champ_value_for('regions')).to eq('Martinique')
    expect(champ_value_for('departements')).to eq('Aisne')
    expect(champ_value_for('communes')).to eq('Brétigny')
    expect(champ_value_for('dossier_link')).to eq('123')
    expect(champ_value_for('piece_justificative')).to be_nil # antivirus hasn't approved the file yet

    ## check data on the gui

    expect(page).to have_field('text', with: 'super texte')
    expect(page).to have_field('textarea', with: 'super textarea')
    expect(page).to have_field('date', with: '2012-12-12')
    expect(page).to have_field('datetime', with: '2023-01-06T07:05')
    expect(page).to have_field('number', with: '42')
    expect(page).to have_checked_field('checkbox')
    expect(page).to have_checked_field('Madame')
    expect(page).to have_field('email', with: 'loulou@yopmail.com')
    expect(page).to have_field('phone', with: '0123456789')
    expect(page).to have_checked_field('Non')
    expect(page).to have_checked_field('val2')
    expect(page).to have_checked_field('val1')
    expect(page).to have_checked_field('val3')
    expect(page).to have_selected_value('simple_choice_drop_down_list_long', selected: 'bravo')
    expect(page).to have_selected_value('pays', selected: 'Australie')
    expect(page).to have_selected_value('regions', selected: 'Martinique')
    expect(page).to have_selected_value('departements', selected: '02 – Aisne')
    within("##{champ_for('multiple_choice_drop_down_list_long').input_group_id}") do
      expect(page).to have_button('alpha')
      expect(page).to have_button('charly')
    end
    expect(page).to have_selected_value('communes', selected: 'Brétigny (60400)')
    expect(page).to have_selected_value('pays', selected: 'Australie')
    expect(page).to have_field('dossier_link', with: '123')
    expect(page).to have_text('file.pdf')
    expect(page).to have_text('Analyse antivirus en cours')
  end

  let(:procedure_with_repetition) do
    create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :repetition, mandatory: true, children: [{ libelle: 'sub type de champ' }] }])
  end

  scenario 'fill a dossier with repetition', js: true do
    log_in(user, procedure_with_repetition)

    fill_individual

    fill_in('sub type de champ', with: 'super texte')
    expect(page).to have_field('sub type de champ', with: 'super texte')

    click_on 'Ajouter un élément pour'

    within '.repetition .row:first-child' do
      fill_in('sub type de champ', with: 'un autre texte')
    end

    expect(page).to have_content('Supprimer', count: 2)

    expect do
      within '.repetition .row:first-child' do
        click_on 'Supprimer l’élément'
      end
      expect(page).to have_content('Supprimer', count: 1)
    end.to change { Champ.count }
  end

  let(:simple_procedure) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ mandatory: true, libelle: 'texte obligatoire' }, { mandatory: false, libelle: 'texte optionnel' }]) }

  scenario 'save an incomplete dossier as draft but cannot not submit it', js: true do
    log_in(user, simple_procedure)
    fill_individual

    # Check an incomplete dossier can be saved as a draft, even when mandatory fields are missing
    fill_in('texte optionnel', with: 'ça ne suffira pas')
    wait_for_autosave

    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check an incomplete dossier cannot be submitted when mandatory fields are missing
    click_on 'Déposer le dossier'
    expect(user_dossier.reload.brouillon?).to be(true)
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check a dossier can be submitted when all mandatory fields are filled
    fill_in('texte obligatoire', with: 'super texte')
    wait_for_autosave

    click_on 'Déposer le dossier'
    wait_until { user_dossier.reload.en_construction? }
    expect(champ_value_for('texte obligatoire')).to eq('super texte')
    expect(page).to have_current_path(merci_dossier_path(user_dossier))
  end

  scenario 'extends dossier experation date more than one time, ', js: true do
    simple_procedure.update(procedure_expires_when_termine_enabled: true)
    user_old_dossier = create(:dossier,
                              procedure: simple_procedure,
                              created_at: simple_procedure.duree_conservation_dossiers_dans_ds.month.ago,
                              user: user)
    login_as(user, scope: :user)
    visit brouillon_dossier_path(user_old_dossier)

    expect(page).to have_css('.fr-callout__title', text: 'Votre dossier va expirer', visible: true)
    find('#test-user-repousser-expiration').click
    expect(page).to have_no_selector('#test-user-repousser-expiration')

    Timecop.freeze(simple_procedure.duree_conservation_dossiers_dans_ds.month.from_now) do
      visit brouillon_dossier_path(user_old_dossier)
      expect(page).to have_css('.fr-callout__title', text: 'Votre dossier va expirer', visible: true)
      find('#test-user-repousser-expiration').click
      expect(page).to have_no_selector('#test-user-repousser-expiration')
    end
  end

  let(:procedure_with_pj) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :piece_justificative, mandatory: true, libelle: 'Pièce justificative' }]) }
  let(:procedure_with_pjs) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :piece_justificative, mandatory: true, libelle: 'Pièce justificative 1' }, { type: :piece_justificative, mandatory: true, libelle: 'Pièce justificative 2' }]) }
  let(:old_procedure_with_disabled_pj_validation) { create(:procedure, :published, :for_individual, types_de_champ_public: [{ type: :piece_justificative, mandatory: true, libelle: 'Pièce justificative 1', skip_pj_validation: true }]) }

  scenario 'add an attachment', js: true do
    log_in(user, procedure_with_pjs)
    fill_individual

    # Add attachments
    find_field('Pièce justificative 1').attach_file(Rails.root + 'spec/fixtures/files/file.pdf')
    find_field('Pièce justificative 2').attach_file(Rails.root + 'spec/fixtures/files/RIB.pdf')

    # Expect the files to be uploaded immediately
    expect(page).to have_text('Analyse antivirus en cours', count: 2, wait: 5)
    expect(page).to have_text('file.pdf')
    expect(page).to have_text('RIB.pdf')

    # Expect the submit buttons to be enabled
    expect(page).to have_button('Déposer le dossier', disabled: false)

    # Reload the current page
    visit current_path

    # Expect the files to have been saved on the dossier
    expect(page).to have_text('file.pdf')
    expect(page).to have_text('RIB.pdf')
  end

  scenario 'add an invalid attachment on an old procedure where pj validation is disabled', js: true do
    log_in(user, old_procedure_with_disabled_pj_validation)
    fill_individual

    # Test invalid file type
    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/invalid_file_format.json')
    expect(page).to have_no_text('La pièce justificative n’est pas d’un type accepté')
    expect(page).to have_text('Analyse antivirus en cours', count: 1, wait: 5)
  end

  scenario 'retry on transcient upload error', js: true do
    log_in(user, procedure_with_pjs)
    fill_individual

    # Test auto-upload failure
    # Make the subsequent auto-upload request fail
    allow_any_instance_of(Champs::PieceJustificativeController).to receive(:update) do |instance|
      instance.render json: { errors: ["Une erreur est survenue"] }, status: :bad_request
    end
    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/file.pdf')
    expect(page).to have_css('p', text: "Une erreur est survenue", visible: :visible, wait: 5)
    expect(page).to have_button('Réessayer', visible: true)
    expect(page).to have_button('Déposer le dossier', disabled: false)

    allow_any_instance_of(Champs::PieceJustificativeController).to receive(:update).and_call_original

    # Test that retrying after a failure works
    click_on('Réessayer', visible: true, wait: 5)
    expect(page).to have_text('Analyse antivirus en cours', wait: 5)
    expect(page).to have_text('file.pdf')
    expect(page).to have_button('Déposer le dossier', disabled: false)

    # Reload the current page
    visit current_path

    # Expect the file to have been saved on the dossier
    expect(page).to have_text('file.pdf')
  end

  scenario "upload multiple pieces justificatives on same champ", js: true do
    log_in(user, procedure_with_pjs)
    fill_individual

    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/file.pdf')
    expect(page).to have_text('file.pdf')
    expect(page).to have_text('Analyse antivirus en cours')

    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/white.png')
    expect(page).to have_text('white.png')

    click_on("Supprimer le fichier file.pdf")
    expect(page).not_to have_text('file.pdf')
    expect(page).to have_text("La pièce jointe a bien été supprimée")

    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/black.png')

    # Mark all attachments as safe to test turbo poll
    # They are not immediately attached in db, so we have to wait a bit before continuing
    # NOTE: we're using files not used in other tests to avoid conflicts with concurrent tests
    attachments = Timeout.timeout(5) do
      filenames = ['white.png', 'black.png']
      attachments = ActiveStorage::Attachment.where(name: "piece_justificative_file").includes(:blob).filter do |attachment|
        filenames.include?(attachment.filename.to_s)
      end

      fail ActiveRecord::RecordNotFound, "Not all attachments where found yet" unless attachments.count == filenames.count

      attachments
    rescue ActiveRecord::RecordNotFound
      sleep 0.2
      retry
    end

    attachments.each {
      _1.blob.virus_scan_result = ActiveStorage::VirusScanner::SAFE
      _1.save!
    }
    expect(page).not_to have_text('Analyse antivirus en cours', wait: 10)

    visit current_path

    expect(page).not_to have_text('file.pdf')
    expect(page).to have_text('white.png')
    expect(page).to have_text('black.png')
  end

  context 'with condition' do
    include Logic

    context 'with a repetition' do
      let(:stable_id) { 999 }
      let(:condition) { greater_than_eq(champ_value(stable_id), constant(18)) }
      let(:procedure) do
        create(:procedure, :published, :for_individual,
          types_de_champ_public: [
            { type: :integer_number, libelle: 'age', stable_id: },
            {
              type: :repetition, libelle: 'repetition', condition:, children: [
                { type: :text, libelle: 'nom', mandatory: true }
              ]
            }
          ])
      end

      scenario 'submit a dossier with an hidden mandatory champ within a repetition', js: true do
        log_in(user, procedure)

        fill_individual

        fill_in('age', with: 10)
        click_on 'Déposer le dossier'
        expect(page).to have_current_path(merci_dossier_path(user_dossier))
      end
    end

    context 'with a condition inside repetition' do
      let(:a_stable_id) { 999 }
      let(:b_stable_id) { 9999 }
      let(:a_condition) { ds_eq(champ_value(a_stable_id), constant(true)) }
      let(:b_condition) { ds_eq(champ_value(b_stable_id), constant(true)) }
      let(:condition) { ds_or([a_condition, b_condition]) }
      let(:procedure) do
        create(:procedure, :published, :for_individual,
          types_de_champ_public: [
            { type: :checkbox, libelle: 'champ_a', stable_id: a_stable_id },
            {
              type: :repetition, libelle: 'repetition', mandatory: true, children: [
                { type: :checkbox, libelle: 'champ_b', stable_id: b_stable_id },
                { type: :text, libelle: 'champ_c', condition: }
              ]
            }
          ])
      end

      scenario 'fill a dossier', js: true do
        log_in(user, procedure)

        fill_individual

        expect(page).to have_no_css('label', text: 'champ_c', visible: true)
        check('champ_a')
        wait_for_autosave

        expect(page).to have_css('label', text: 'champ_c', visible: true)
        uncheck('champ_a')
        wait_for_autosave

        expect(page).to have_no_css('label', text: 'champ_c', visible: true)
        check('champ_b')
        wait_for_autosave

        expect(page).to have_css('label', text: 'champ_c', visible: true)
      end
    end

    context 'with a required conditionnal champ' do
      let(:stable_id) { 999 }
      let(:condition) { greater_than_eq(champ_value(stable_id), constant(18)) }
      let(:procedure) do
        create(:procedure, :published, :for_individual,
          types_de_champ_public: [
            { type: :integer_number, libelle: 'age', stable_id: },
            { type: :text, libelle: 'nom', mandatory: true, condition: }
          ])
      end

      scenario 'submit a dossier with an hidden mandatory champ ', js: true do
        log_in(user, procedure)

        fill_individual

        click_on 'Déposer le dossier'
        expect(page).to have_current_path(merci_dossier_path(user_dossier))
      end

      scenario 'cannot submit a reveal dossier with a revealed mandatory champ ', js: true do
        log_in(user, procedure)

        fill_individual

        fill_in('age', with: '18')
        expect(page).to have_css('label', text: 'nom *', visible: :visible)

        click_on 'Déposer le dossier'
        expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
      end
    end

    context 'with a visibilite in cascade' do
      let(:age_stable_id) { 999 }
      let(:permis_stable_id) { 9999 }
      let(:tonnage_stable_id) { 99999 }
      let(:permis_condition) { greater_than_eq(champ_value(age_stable_id), constant(18)) }
      let(:tonnage_condition) { ds_eq(champ_value(permis_stable_id), constant(true)) }
      let(:parking_condition) { less_than_eq(champ_value(tonnage_stable_id), constant(20)) }

      let(:procedure) do
        create(:procedure, :published, :for_individual,
          types_de_champ_public: [
            { type: :integer_number, libelle: 'age', stable_id: age_stable_id },
            { type: :yes_no, libelle: 'permis de conduire', stable_id: permis_stable_id, condition: permis_condition },
            { type: :header_section, libelle: 'info voiture', condition: permis_condition },
            { type: :integer_number, libelle: 'tonnage', stable_id: tonnage_stable_id, condition: tonnage_condition },
            { type: :text, libelle: 'parking', condition: parking_condition }
          ])
      end

      scenario 'fill a dossier', js: true do
        log_in(user, procedure)

        fill_individual

        expect(page).to have_css('label', text: 'age', visible: true)
        expect(page).to have_no_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_no_css('legend h2', text: 'info voiture', visible: true)
        expect(page).to have_no_css('label', text: 'tonnage', visible: true)

        fill_in('age', with: '18')
        expect(page).to have_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_css('legend h2', text: 'info voiture', visible: true)
        expect(page).to have_no_css('label', text: 'tonnage', visible: true)


        choose('Oui')
        expect(page).to have_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_css('label', text: 'tonnage', visible: true)


        fill_in('tonnage', with: '1')
        expect(page).to have_css('label', text: 'parking', visible: true)

        # try to fill with invalid data
        fill_in('tonnage', with: 'a')
        expect(page).to have_no_css('label', text: 'parking', visible: true)

        fill_in('age', with: '2')
        expect(page).to have_no_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_no_css('label', text: 'tonnage', visible: true)

        click_on 'Déposer le dossier'
        click_on 'Accéder à votre dossier'
        click_on 'Modifier mon dossier'

        expect(page).to have_css('label', text: 'age', visible: true)
        expect(page).to have_no_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_no_css('label', text: 'tonnage', visible: true)

        fill_in('age', with: '18')
        wait_for_autosave(false)

        # the champ keeps their previous value so they are all displayed
        expect(page).to have_css('label', text: 'permis de conduire', visible: true)
        expect(page).to have_css('label', text: 'tonnage', visible: true)
      end
    end
  end

  context 'draft autosave' do
    scenario 'autosave a draft', js: true do
      log_in(user, simple_procedure)
      fill_individual

      expect(page).to have_no_button('Enregistrer le brouillon')
      expect(page).to have_content('Votre brouillon est automatiquement enregistré')

      fill_in('texte obligatoire', with: 'a valid user input')
      wait_for_autosave

      visit current_path
      expect(page).to have_field('texte obligatoire', with: 'a valid user input')
    end

    scenario 'retry on autosave error', :capybara_ignore_server_errors, js: true do
      log_in(user, simple_procedure)
      fill_individual

      # Test autosave failure
      allow_any_instance_of(Users::DossiersController).to receive(:update_brouillon).and_raise("Server is busy")
      fill_in('texte obligatoire', with: 'a valid user input')
      blur
      expect(page).to have_css('span', text: 'Impossible d’enregistrer le brouillon', visible: true)

      # Test that retrying after a failure works
      allow_any_instance_of(Users::DossiersController).to receive(:update_brouillon).and_call_original
      click_on 'réessayer'
      wait_for_autosave

      visit current_path
      expect(page).to have_field('texte obligatoire', with: 'a valid user input')
    end

    scenario 'autosave redirects to sign-in after being disconnected', js: true do
      log_in(user, simple_procedure)
      fill_individual

      # When the user is disconnected
      # (either because signing-out in another tab, or because the session cookie expired)
      logout(:user)
      fill_in('texte obligatoire', with: 'a valid user input')
      blur

      # … they are redirected to the sign-in page.
      expect(page).to have_current_path(new_user_session_path)

      # After sign-in, they are redirected back to their brouillon
      sign_in_with(user.email, password)
      expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

      fill_in('texte obligatoire', with: 'a valid user input')
      wait_for_autosave
    end
  end

  private

  def log_in(user, procedure)
    login_as user, scope: :user

    visit "/commencer/#{procedure.path}"
    click_on 'Commencer la démarche'

    expect(page).to have_content("Données d’identité")
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def champ_value_for(libelle)
    champ_for(libelle).value
  end

  def champ_for(libelle)
    champs = user_dossier.reload.champs_public
    champs.find { |c| c.libelle == libelle }
  end

  def fill_individual
    choose 'Monsieur'
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    click_on 'Continuer'
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end
end
