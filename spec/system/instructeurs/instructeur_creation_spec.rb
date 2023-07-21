describe 'As an instructeur', js: true do
  let(:administrateur) { create(:administrateur, :with_procedure) }
  let(:procedure) { administrateur.procedures.first }
  let(:instructeur_email) { 'new_instructeur@gouv.fr' }

  before do
    login_as administrateur.user, scope: :user

    visit admin_procedure_path(procedure)
    find('#groupe-instructeurs').click

    fill_in 'Emails', with: instructeur_email
    perform_enqueued_jobs { click_on 'Affecter' }

    expect(page).to have_text("Les instructeurs ont bien été affectés à la démarche")
  end

  scenario 'I can register' do
    confirmation_email = open_email(instructeur_email)
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "users/activate?#{token_params}"
    expect(page).to have_content 'Choix du mot de passe'
    fill_in :user_password, with: TEST_PASSWORD

    click_button 'Continuer'

    expect(page).to have_content 'Mot de passe enregistré'
  end
end
