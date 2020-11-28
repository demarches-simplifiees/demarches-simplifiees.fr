feature 'As an administrateur', js: true do
  let(:super_admin) { create(:super_admin) }
  let(:admin_email) { 'new_admin@gouv.fr' }
  let(:new_admin) { Administrateur.by_email(admin_email) }

  before do
    perform_enqueued_jobs do
      super_admin.invite_admin(admin_email)
    end
  end

  scenario 'I can register' do
    expect(new_admin.reload.user.active?).to be(false)

    confirmation_email = open_email(admin_email)
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "admin/activate?#{token_params}"
    fill_in :administrateur_password, with: TEST_PASSWORD

    click_button 'Définir le mot de passe'

    expect(page).to have_content 'Mot de passe enregistré'

    expect(new_admin.reload.user.active?).to be(true)
  end
end
