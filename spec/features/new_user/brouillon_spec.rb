require 'spec_helper'

feature 'The user' do
  let(:password) { 'secret_password' }
  let!(:user) { create(:user, password: password) }

  let!(:procedure) { create(:procedure, :published, :for_individual, :with_all_champs_mandatory) }
  let(:user_dossier) { user.dossiers.first }

  # TODO: check
  # the order
  # there are no extraneous input
  # attached file works
  scenario 'fill a dossier', js: true do
    allow(Champs::RegionChamp).to receive(:regions).and_return(['region1', 'region2']).at_least(:once)
    allow(Champs::DepartementChamp).to receive(:departements).and_return(['dep1', 'dep2']).at_least(:once)

    log_in(user.email, password, procedure)

    fill_individual

    # fill data
    fill_in('text', with: 'super texte')
    fill_in('textarea', with: 'super textarea')
    fill_in('date', with: '12/12/2012')
    select_date_and_time(DateTime.parse('06/01/1985 7h05'), form_id_for('datetime'))
    fill_in('number', with: '42')
    check('checkbox')
    choose('Madame')
    fill_in('email', with: 'loulou@yopmail.com')
    fill_in('phone', with: '1234567890')
    choose('Non')
    select('val2', from: form_id_for('simple_drop_down_list'))
    select('val1', from: form_id_for('multiple_drop_down_list'))
    select('val3', from: form_id_for('multiple_drop_down_list'))
    select('AUSTRALIE', from: 'pays')
    select('region2', from: 'regions')
    select('dep2', from: 'departements')
    check('engagement')
    fill_in('dossier_link', with: '123')
    # do not know how to make it work...
    # find('form input[type="file"]').set(Rails.root.join('spec/fixtures/white.png'))

    click_on 'Enregistrer le brouillon'

    # check data on the dossier
    expect(user_dossier.brouillon?).to be true
    expect(champ_value_for('text')).to eq('super texte')
    expect(champ_value_for('textarea')).to eq('super textarea')
    expect(champ_value_for('date')).to eq('2012-12-12')
    expect(champ_value_for('datetime')).to eq('06/01/1985 07:05')
    expect(champ_value_for('number')).to eq('42')
    expect(champ_value_for('checkbox')).to eq('on')
    expect(champ_value_for('civilite')).to eq('Mme.')
    expect(champ_value_for('email')).to eq('loulou@yopmail.com')
    expect(champ_value_for('phone')).to eq('1234567890')
    expect(champ_value_for('yes_no')).to eq('false')
    expect(champ_value_for('simple_drop_down_list')).to eq('val2')
    expect(JSON.parse(champ_value_for('multiple_drop_down_list'))).to match(['val1', 'val3'])
    expect(champ_value_for('pays')).to eq('AUSTRALIE')
    expect(champ_value_for('regions')).to eq('region2')
    expect(champ_value_for('departements')).to eq('dep2')
    expect(champ_value_for('engagement')).to eq('on')
    expect(champ_value_for('dossier_link')).to eq('123')

    ## check data on the gui
    expect(page).to have_field('text', with: 'super texte')
    expect(page).to have_field('textarea', with: 'super textarea')
    expect(page).to have_field('date', with: '2012-12-12')
    check_date_and_time(DateTime.parse('06/01/1985 7:05'), form_id_for('datetime'))
    expect(page).to have_field('number', with: '42')
    expect(page).to have_checked_field('checkbox')
    expect(page).to have_checked_field('Madame')
    expect(page).to have_field('email', with: 'loulou@yopmail.com')
    expect(page).to have_field('phone', with: '1234567890')
    expect(page).to have_checked_field('Non')
    expect(page).to have_select('simple_drop_down_list', selected: 'val2')
    expect(page).to have_select('multiple_drop_down_list', selected: ['val1', 'val3'])
    expect(page).to have_select('pays', selected: 'AUSTRALIE')
    expect(page).to have_select('regions', selected: 'region2')
    expect(page).to have_select('departement', selected: 'dep2')
    expect(page).to have_checked_field('engagement')
    expect(page).to have_field('dossier_link', with: '123')
  end

  let(:simple_procedure) do
    tdcs = [create(:type_de_champ, mandatory: true, libelle: 'texte obligatoire')]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end

  scenario 'save an incomplete dossier as draft but cannot not submit it', js: true do
    log_in(user.email, password, simple_procedure)
    fill_individual

    # Check an incomplete dossier can be saved as a draft, even when mandatory fields are missing
    click_on 'Enregistrer le brouillon'
    expect(user_dossier.reload.brouillon?).to be(true)
    expect(page).to have_content('Votre brouillon a bien été sauvegardé')
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check an incomplete dossier cannot be submitted when mandatory fields are missing
    click_on 'Soumettre le dossier'
    expect(user_dossier.reload.brouillon?).to be(true)
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))

    # Check a dossier can be submitted when all mandatory fields are filled
    fill_in('texte obligatoire', with: 'super texte')

    click_on 'Soumettre le dossier'
    expect(user_dossier.reload.en_construction?).to be(true)
    expect(champ_value_for('texte obligatoire')).to eq('super texte')
    expect(page).to have_current_path(merci_dossier_path(user_dossier))
  end

  scenario 'delete a draft', js: true do
    log_in(user.email, password, simple_procedure)
    fill_individual

    page.accept_alert('Confirmer la suppression ?') do
      click_on 'Supprimer le brouillon'
    end

    expect(page).to have_current_path(dossiers_path)
    expect(page).to have_text('Votre dossier a bien été supprimé')
    expect(page).not_to have_text(user_dossier.procedure.libelle)
    expect(user_dossier.reload.hidden_at).to be_present
  end

  private

  def log_in(email, password, procedure)
    visit "/commencer/#{procedure.procedure_path.path}"
    expect(page).to have_current_path(new_user_session_path)

    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_on 'Se connecter'
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def form_id_for(libelle)
    find(:xpath, ".//label[contains(text()[normalize-space()], '#{libelle}')]")[:for]
  end

  def champ_value_for(libelle)
    champs = user_dossier.champs
    champs.find { |c| c.libelle == libelle }.value
  end

  def fill_individual
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    check 'dossier_autorisation_donnees'
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
    expect(page).to have_select("#{field}_1i", selected: date.strftime('%Y'))
    expect(page).to have_select("#{field}_2i", selected: I18n.l(date, format: '%B'))
    expect(page).to have_select("#{field}_3i", selected: date.strftime('%-d'))
    expect(page).to have_select("#{field}_4i", selected: date.strftime('%H'))
    expect(page).to have_select("#{field}_5i", selected: date.strftime('%M'))
  end
end
