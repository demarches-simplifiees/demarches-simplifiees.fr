feature 'The user' do
  let(:password) { TEST_PASSWORD }
  let!(:user) { create(:user, password: password) }

  let!(:procedure) { create(:procedure, :published, :for_individual, :with_all_champs_mandatory) }
  let(:user_dossier) { user.dossiers.first }

  scenario 'fill a dossier', js: true do
    log_in(user, procedure)

    fill_individual

    # fill data
    fill_in('text', with: 'super texte')
    fill_in('textarea', with: 'super textarea')
    fill_in('date', with: '12-12-2012')
    select_date_and_time(Time.zone.parse('06/01/2030 7h05'), form_id_for_datetime('datetime'))
    fill_in('number', with: '42')
    check('checkbox')
    choose('Madame')
    fill_in('email', with: 'loulou@yopmail.com')
    fill_in('phone', with: '0123456789')
    choose('Non')
    choose('val2')
    check('val1')
    check('val3')
    select('bravo', from: form_id_for('simple_choice_drop_down_list_long'))
    select_multi('multiple_choice_drop_down_list_long', 'alpha')
    select_multi('multiple_choice_drop_down_list_long', 'charly')

    select_champ_geo('pays', 'aust', 'AUSTRALIE')

    select_champ_geo('regions', 'Ma', 'Martinique')

    select_champ_geo('departements', 'Ai', '02 - Aisne')

    select_champ_geo('communes', 'Ambl', 'Ambléon (01300)')

    select('Australienne', from: 'nationalites')
    select('Mahina - Tahiti - 98709', from: 'commune_de_polynesie')
    select('98709 - Mahina - Tahiti', from: 'code_postal_de_polynesie')

    check('engagement')
    fill_in('dossier_link', with: '123')
    find('.editable-champ-piece_justificative input[type=file]').attach_file(Rails.root + 'spec/fixtures/files/file.pdf')

    blur
    sleep(0.7)
    expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

    # check data on the dossier
    expect(user_dossier.brouillon?).to be true
    expect(champ_value_for('text')).to eq('super texte')
    expect(champ_value_for('textarea')).to eq('super textarea')
    expect(champ_value_for('date')).to eq('2012-12-12')
    expect(champ_value_for('datetime')).to eq('06/01/2030 07:05')
    expect(champ_value_for('number')).to eq('42')
    expect(champ_value_for('checkbox')).to eq('on')
    expect(champ_value_for('civilite')).to eq('Mme')
    expect(champ_value_for('email')).to eq('loulou@yopmail.com')
    expect(champ_value_for('phone')).to eq('0123456789')
    expect(champ_value_for('yes_no')).to eq('false')
    expect(champ_value_for('simple_drop_down_list')).to eq('val2')
    expect(champ_value_for('simple_choice_drop_down_list_long')).to eq('bravo')
    expect(JSON.parse(champ_value_for('multiple_choice_drop_down_list_long'))).to match(['alpha', 'charly'])
    expect(JSON.parse(champ_value_for('multiple_drop_down_list'))).to match(['val1', 'val3'])
    expect(champ_value_for('pays')).to eq('AUSTRALIE')
    expect(champ_value_for('regions')).to eq('Martinique')
    expect(champ_value_for('departements')).to eq('02 - Aisne')
    expect(champ_value_for('communes')).to eq('Ambléon (01300)')

    expect(champ_value_for('nationalites')).to eq('Australienne')
    expect(champ_value_for('commune_de_polynesie')).to eq('Mahina - Tahiti - 98709')
    expect(champ_value_for('code_postal_de_polynesie')).to eq('98709 - Mahina - Tahiti')

    expect(champ_value_for('engagement')).to eq('on')
    expect(champ_value_for('dossier_link')).to eq('123')
    expect(champ_value_for('piece_justificative')).to be_nil # antivirus hasn't approved the file yet

    ## check data on the gui

    expect(page).to have_field('text', with: 'super texte')
    expect(page).to have_field('textarea', with: 'super textarea')
    expect(page).to have_field('date', with: '2012-12-12')
    check_date_and_time(Time.zone.parse('06/01/2030 7:05'), form_id_for_datetime('datetime'))
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
    check_selected_values('multiple_choice_drop_down_list_long', ['alpha', 'charly'])

    expect(page).to have_selected_value('nationalites', selected: 'Australienne')
    expect(page).to have_selected_value('commune_de_polynesie', selected: 'Mahina - Tahiti - 98709')
    expect(page).to have_selected_value('code_postal_de_polynesie', selected: '98709 - Mahina - Tahiti')

    expect(page).to have_hidden_field('pays', with: 'AUSTRALIE')
    expect(page).to have_hidden_field('regions', with: 'Martinique')
    expect(page).to have_hidden_field('departements', with: '02 - Aisne')
    expect(page).to have_hidden_field('communes', with: 'Ambléon (01300)')
    expect(page).to have_checked_field('engagement')
    expect(page).to have_field('dossier_link', with: '123')
    expect(page).to have_text('file.pdf')
    expect(page).to have_text('analyse antivirus en cours')
  end

  let(:procedure_with_repetition) do
    create(:procedure, :published, :for_individual, :with_repetition)
  end

  scenario 'fill a dossier with repetition', js: true do
    log_in(user, procedure_with_repetition)

    fill_individual

    fill_in('sub type de champ', with: 'super texte')
    expect(page).to have_field('sub type de champ', with: 'super texte')

    click_on 'Ajouter un élément pour'

    within '.row-1' do
      fill_in('sub type de champ', with: 'un autre texte')
    end

    expect(page).to have_content('Supprimer', count: 2)

    blur
    expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

    expect(page).to have_content('Supprimer', count: 2)

    within '.row-1' do
      click_on 'Supprimer l’élément'
    end

    blur
    expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

    expect(page).to have_content('Supprimer', count: 1)
  end

  let(:simple_procedure) do
    tdcs = [
      build(:type_de_champ, mandatory: true, libelle: 'texte obligatoire'),
      build(:type_de_champ, mandatory: false, libelle: 'texte optionnel')
    ]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end

  scenario 'save an incomplete dossier as draft but cannot not submit it', js: true do
    log_in(user, simple_procedure)
    fill_individual

    # Check an incomplete dossier can be saved as a draft, even when mandatory fields are missing
    fill_in('texte optionnel', with: 'ça ne suffira pas')
    blur
    expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check an incomplete dossier cannot be submitted when mandatory fields are missing
    click_on 'Déposer le dossier'
    expect(user_dossier.reload.brouillon?).to be(true)
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check a dossier can be submitted when all mandatory fields are filled
    fill_in('texte obligatoire', with: 'super texte')

    click_on 'Déposer le dossier'
    expect(user_dossier.reload.en_construction?).to be(true)
    expect(champ_value_for('texte obligatoire')).to eq('super texte')
    expect(page).to have_current_path(merci_dossier_path(user_dossier))
  end

  let(:procedure_with_pj) do
    tdcs = [build(:type_de_champ_piece_justificative, mandatory: true, libelle: 'Pièce justificative')]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end

  let(:procedure_with_pjs) do
    tdcs = [
      build(:type_de_champ_piece_justificative, mandatory: true, libelle: 'Pièce justificative 1', position: 1),
      build(:type_de_champ_piece_justificative, mandatory: true, libelle: 'Pièce justificative 2', position: 2)
    ]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end

  let(:old_procedure_with_disabled_pj_validation) do
    tdcs = [
      create(:type_de_champ_piece_justificative, mandatory: true, libelle: 'Pièce justificative 1', order_place: 1, skip_pj_validation: true)
    ]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end

  scenario 'add an attachment', js: true do
    log_in(user, procedure_with_pjs)
    fill_individual

    # Add attachments
    find_field('Pièce justificative 1').attach_file(Rails.root + 'spec/fixtures/files/file.pdf')
    find_field('Pièce justificative 2').attach_file(Rails.root + 'spec/fixtures/files/RIB.pdf')

    # Expect the files to be uploaded immediately
    expect(page).to have_text('analyse antivirus en cours', count: 2)
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
    expect(page).to have_text('analyse antivirus en cours', count: 1)
  end

  scenario 'retry on transcient upload error', js: true do
    log_in(user, procedure_with_pjs)
    fill_individual

    # Test auto-upload failure
    logout(:user) # Make the subsequent auto-upload request fail
    attach_file('Pièce justificative 1', Rails.root + 'spec/fixtures/files/file.pdf')
    expect(page).to have_text('Une erreur s’est produite pendant l’envoi du fichier')
    expect(page).to have_button('Ré-essayer', visible: true)
    expect(page).to have_button('Déposer le dossier', disabled: false)

    # Test that retrying after a failure works
    login_as(user, scope: :user) # Make the auto-upload request work again
    click_on('Ré-essayer', visible: true)
    expect(page).to have_text('analyse antivirus en cours')
    expect(page).to have_text('file.pdf')
    expect(page).to have_button('Déposer le dossier', disabled: false)

    # Reload the current page
    visit current_path

    # Expect the file to have been saved on the dossier
    expect(page).to have_text('file.pdf')
  end

  context 'draft autosave' do
    scenario 'autosave a draft', js: true do
      log_in(user, simple_procedure)
      fill_individual

      expect(page).not_to have_button('Enregistrer le brouillon')
      expect(page).to have_content('Votre brouillon est automatiquement enregistré')

      fill_in('texte obligatoire', with: 'a valid user input')
      blur

      expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

      visit current_path
      expect(page).to have_field('texte obligatoire', with: 'a valid user input')
    end

    scenario 'retry on autosave error', js: true do
      log_in(user, simple_procedure)
      fill_individual

      # Test autosave failure
      logout(:user) # Make the subsequent autosave requests fail
      fill_in('texte obligatoire', with: 'a valid user input')
      blur
      expect(page).to have_css('span', text: 'Impossible d’enregistrer le brouillon', visible: true)

      # Test that retrying after a failure works
      login_as(user, scope: :user) # Make the autosave requests work again
      click_on 'réessayer'
      expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

      visit current_path
      expect(page).to have_field('texte obligatoire', with: 'a valid user input')
    end
  end

  private

  def log_in(user, procedure)
    login_as user, scope: :user

    visit "/commencer/#{procedure.path}"
    click_on 'Commencer la démarche'

    expect(page).to have_content("Données d'identité")
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def form_id_for(libelle)
    find(:xpath, ".//label[contains(text()[normalize-space()], '#{libelle}')]")[:for]
  end

  def form_id_for_datetime(libelle)
    # The HTML for datetime is a bit specific since it has 5 selects, below here is a sample HTML
    # So, we want to find the partial id of a datetime (partial because there are 5 ids:
    # dossier_champs_attributes_3_value_1i, 2i, ... 5i) ; we are interested in the 'dossier_champs_attributes_3_value' part
    # which is then completed in select_date_and_time and check_date_and_time
    #
    # We find the H2, find the first select in the next .datetime div, then strip the last 3 characters
    #
    # <h4 class="form-label">
    #   libelle
    # </h4>
    # <div class="datetime">
    #     <span class="hidden">
    #         <label for="dossier_champs_attributes_3_value_3i">Jour</label></span>
    #     <select id="dossier_champs_attributes_3_value_3i" name="dossier[champs_attributes][3][value(3i)]">
    #     <option value=""></option>
    #     <option value="1">1</option>
    #     <option value="2">2</option>
    #     <!-- … -->
    #     </select>
    #     <!-- … 4 other selects for month, year, minute and seconds -->
    # </div>
    e = find(:xpath, ".//div[contains(text()[normalize-space()], '#{libelle}')]")
    e.sibling('.datetime').first('select')[:id][0..-4]
  end

  def have_hidden_field(libelle, with:)
    have_css("##{form_id_for(libelle)}[value=\"#{with}\"]")
  end

  def champ_value_for(libelle)
    champs = user_dossier.champs
    champs.find { |c| c.libelle == libelle }.value
  end

  def fill_individual
    choose 'Monsieur'
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    click_on 'Continuer'
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end

  def select_date_and_time(date, field)
    select date.strftime('%Y'), from: "#{field}_1i" # year
    select I18n.l(date, format: '%B'), from: "#{field}_2i" # month
    select date.strftime('%-d'), from: "#{field}_3i" # day
    select date.strftime('%H'), from: "#{field}_4i" # hour
    select date.strftime('%M'), from: "#{field}_5i" # minute
  end

  def check_date_and_time(date, field)
    expect(page).to have_selected_value("#{field}_1i", selected: date.strftime('%Y'))
    expect(page).to have_selected_value("#{field}_2i", selected: I18n.l(date, format: '%B'))
    expect(page).to have_selected_value("#{field}_3i", selected: date.strftime('%-d'))
    expect(page).to have_selected_value("#{field}_4i", selected: date.strftime('%H'))
    expect(page).to have_selected_value("#{field}_5i", selected: date.strftime('%M'))
  end

  def select_champ_geo(champ, fill_with, value)
    input = find("input[aria-label=#{champ}")
    input.click
    input.fill_in with: fill_with
    selector = "li[data-option-value=\"#{value}\"]"
    find(selector).click
    expect(page).to have_css(selector)
    expect(page).to have_hidden_field(champ, with: value)
  end
end
