feature 'As an instructeur', js: true do
  let(:administrateur) { create(:administrateur, :with_procedure) }
  let(:procedure) { administrateur.procedures.first }
  let(:instructeur_email) { 'new_instructeur@gouv.fr' }

  before do
    login_as administrateur.user, scope: :user
    visit admin_instructeurs_path

    fill_in :instructeur_email, with: instructeur_email

    perform_enqueued_jobs do
      click_button 'Ajouter'
    end
  end

  scenario 'I can register' do
    confirmation_email = open_email(instructeur_email)
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "users/activate?#{token_params}"
    expect(page).to have_content 'Choix du mot de passe'
    fill_in :user_password, with: TEST_PASSWORD

    click_button 'Définir le mot de passe'

    expect(page).to have_content 'Mot de passe enregistré'
  end
end
