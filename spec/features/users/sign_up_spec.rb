require 'spec_helper'

feature 'Signing up:' do
  let(:user_email) { generate :user_email }
  let(:user_password) { 'démarches-simplifiées-pwd' }
  let(:procedure) { create :simple_procedure, :with_service }

  scenario 'a new user can sign-up' do
    visit commencer_path(path: procedure.path)
    click_on "Créer un compte #{SITE_NAME}"

    sign_up_with user_email, user_password
    expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

    click_confirmation_link_for user_email
    expect(page).to have_content 'Votre compte a été activé'
    expect(page).to have_current_path commencer_path(path: procedure.path)
  end

  context 'when the user register with a gmail.pf domain' do
    let(:procedure) { create :simple_procedure, :with_service }

    before do
      visit commencer_path(path: procedure.path)
      click_on "Créer un compte #{SITE_NAME}"
      expect(page).to have_selector('.suspect-email', visible: false)
      fill_in 'Email', with: 'bidou@gmail.pf'
      fill_in 'Mot de passe', with: '12345'
    end

    scenario 'they can accept the suggestion', js: true do
      expect(page).to have_selector('.suspect-email', visible: true)
      click_on 'Oui'
      expect(page).to have_field("Email", :with => 'bidou@gmail.com')
    end
  end

  context 'when the user makes a typo in their email address' do
    let(:procedure) { create :simple_procedure, :with_service }

    before do
      visit commencer_path(path: procedure.path)
      click_on "Créer un compte #{SITE_NAME}"
      expect(page).to have_selector('.suspect-email', visible: false)
      fill_in 'Email', with: 'bidou@yahoo.rf'
      fill_in 'Mot de passe', with: '12345'
    end

    scenario 'they can accept the suggestion', js: true do
      expect(page).to have_selector('.suspect-email', visible: true)
      click_on 'Oui'
      expect(page).to have_field("Email", :with => 'bidou@yahoo.fr')
      expect(page).to have_selector('.suspect-email', visible: false)
    end

    scenario 'they can discard the suggestion', js: true do
      expect(page).to have_selector('.suspect-email', visible: true)
      click_on 'Non'
      expect(page).to have_field("Email", :with => 'bidou@yahoo.rf')
      expect(page).to have_selector('.suspect-email', visible: false)
    end

    scenario 'they can fix the typo themselves', js: true do
      expect(page).to have_selector('.suspect-email', visible: true)
      fill_in 'Email', with: 'bidou@yahoo.fr'
      blur
      expect(page).to have_selector('.suspect-email', visible: false)
    end
  end

  scenario 'a new user can’t sign-up with too short password when visiting a procedure' do
    visit commencer_path(path: procedure.path)
    click_on "Créer un compte #{SITE_NAME}"

    expect(page).to have_current_path new_user_registration_path
    sign_up_with user_email, '1234567'
    expect(page).to have_current_path user_registration_path
    expect(page).to have_content 'Le mot de passe est trop court'

    # Then with a good password
    sign_up_with user_email, user_password
    expect(page).to have_current_path new_user_confirmation_path user: { email: user_email }
    expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"
  end

  context 'when visiting a procedure' do
    let(:procedure) { create :simple_procedure, :with_service }

    before do
      visit commencer_path(path: procedure.path)
    end

    scenario 'a new user can sign-up and fill the procedure' do
      click_on 'Créer un compte'
      expect(page).to have_current_path new_user_registration_path
      expect(page).to have_procedure_description(procedure)

      sign_up_with user_email, user_password
      expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

      click_confirmation_link_for user_email

      expect(page).to have_current_path(commencer_path(path: procedure.path))
      expect(page).to have_content 'Votre compte a été activé'
      click_on 'Commencer la démarche'

      expect(page).to have_current_path identite_dossier_path(procedure.reload.dossiers.last)
      expect(page).to have_procedure_description(procedure)
    end
  end

  context 'when a user is not confirmed yet' do
    before do
      visit commencer_path(path: procedure.path)
      click_on "Créer un compte #{SITE_NAME}"

      sign_up_with user_email, user_password
    end

    # Ideally, when signing-in with an unconfirmed account,
    # the user would be redirected to the "resend email confirmation" page.
    #
    # However the check for unconfirmed accounts is made by Warden every time a page is loaded –
    # and much earlier than SessionsController#create.
    #
    # For now only test the default behavior (an error message is displayed).
    scenario 'they get an error message' do
      visit root_path
      click_on 'Connexion'

      sign_in_with user_email, user_password
      expect(page).to have_content 'Vous devez confirmer votre adresse email pour continuer'
    end
  end
end
