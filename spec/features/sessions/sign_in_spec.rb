require 'spec_helper'

feature 'Signin in:' do
  let!(:user) { create(:user, password: password) }
  let(:password) { 'testpassword' }

  scenario 'an existing user can sign-in' do
    visit root_path
    click_on 'Connexion'

    sign_in_with user.email, password

    expect(page).to have_current_path dossiers_path
  end

  context 'when visiting a procedure' do
    let(:procedure) { create :simple_procedure, :with_service }

    before do
      visit commencer_path(path: procedure.path)
    end

    scenario 'an existing user can sign-in and fill the procedure' do
      expect(page).to have_current_path new_user_session_path
      expect_page_to_have_procedure_description(procedure)

      sign_in_with user.email, password

      expect(page).to have_current_path identite_dossier_path(user.reload.dossiers.last)
      expect_page_to_have_procedure_description(procedure)
      expect(page).to have_content "Données d'identité"
    end
  end

  context 'when a user is not confirmed yet' do
    let!(:user) { create(:user, password: password, confirmed_at: nil) }

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

      sign_in_with user.email, password
      expect(page).to have_content 'Vous devez confirmer votre adresse email pour continuer'
    end
  end
end
