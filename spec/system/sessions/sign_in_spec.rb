describe 'Signin in:' do
  let!(:user) { create(:user, password: password) }
  let(:password) { 'my-s3cure-p4ssword' }

  scenario 'an existing user can sign-in' do
    visit root_path
    click_on 'Se connecter', match: :first

    sign_in_with user.email, 'invalid-password'
    expect(page).to have_content 'Adresse éléctronique ou mot de passe incorrect.'
    expect(page).to have_field('Adresse éléctronique', with: user.email)

    sign_in_with user.email, password
    expect(page).to have_current_path dossiers_path
  end

  scenario 'an existing user can lock its account' do
    visit root_path
    click_on 'Se connecter', match: :first

    5.times { sign_in_with user.email, 'bad password' }
    expect(user.reload.access_locked?).to be false

    sign_in_with user.email, 'bad password'
    expect(user.reload.access_locked?).to be true
  end

  context 'when visiting a procedure' do
    let(:procedure) { create :simple_procedure, :with_service }

    before do
      visit commencer_path(path: procedure.path)
    end

    scenario 'an existing user can sign-in and fill the procedure' do
      click_on 'J’ai déjà un compte'
      expect(page).to have_current_path new_user_session_path
      expect(page).to have_procedure_description(procedure)

      sign_in_with user.email, password

      expect(page).to have_current_path(commencer_path(path: procedure.path))
      click_on 'Commencer la démarche'

      expect(page).to have_current_path identite_dossier_path(user.reload.dossiers.last)
      expect(page).to have_procedure_description(procedure)
      expect(page).to have_content "Données d’identité"
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
      click_on 'Se connecter', match: :first

      sign_in_with user.email, password
      expect(page).to have_content('Vous devez confirmer votre compte par courriel.')
    end
  end
end
