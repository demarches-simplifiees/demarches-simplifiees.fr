require 'spec_helper'

feature 'Signin up:' do
  let(:user_email) { generate :user_email }
  let(:user_password) { 'testpassword' }

  scenario 'a new user can sign-up' do
    visit root_path
    click_on 'Connexion'
    click_on 'Créer un compte'

    sign_up_with user_email, user_password
    expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

    click_confirmation_link_for user_email
    expect(page).to have_content 'Votre compte a été activé'
    expect(page).to have_current_path dossiers_path
  end

  context 'when visiting a procedure' do
    let(:procedure) { create :simple_procedure }

    before do
      visit commencer_path(path: procedure.path)
    end

    scenario 'a new user can sign-up and fill the procedure' do
      expect(page).to have_current_path new_user_session_path
      click_on 'Créer un compte'

      sign_up_with user_email, user_password
      expect(page).to have_content "nous avons besoin de vérifier votre adresse #{user_email}"

      click_confirmation_link_for user_email
      expect(page).to have_content 'Votre compte a été activé'
      expect(page).to have_content procedure.libelle
    end
  end

  context 'when a user is not confirmed yet' do
    before do
      visit root_path
      click_on 'Connexion'
      click_on 'Créer un compte'

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
