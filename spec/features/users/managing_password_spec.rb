feature 'Managing password:' do
  context 'for simple users' do
    let(:user) { create(:user) }
    let(:new_password) { 'démarches-simple' } # complexity = 2

    scenario 'a simple user can reset their password' do
      visit root_path
      click_on 'Connexion'
      click_on 'Mot de passe oublié ?'
      expect(page).to have_current_path(new_user_password_path)

      fill_in 'Email', with: user.email
      perform_enqueued_jobs do
        click_on 'Réinitialiser'
      end
      expect(page).to have_content 'vous allez recevoir un lien de réinitialisation par email'

      click_reset_password_link_for user.email
      expect(page).to have_content 'Changement de mot de passe'

      fill_in 'user_password', with: new_password
      # fill_in 'user_password_confirmation', with: new_password
      click_on 'Changer le mot de passe'
      expect(page).to have_content('Votre mot de passe a été changé avec succès')
    end
  end

  context 'for admins' do
    let(:user) { create(:user) }
    let(:administrateur) { create(:administrateur, user: user) }
    let(:new_password) { 'démarches-simplifiées-pwd' }

    scenario 'an admin can reset their password' do
      visit root_path
      click_on 'Connexion'
      click_on 'Mot de passe oublié ?'
      expect(page).to have_current_path(new_user_password_path)

      fill_in 'Email', with: user.email
      perform_enqueued_jobs do
        click_on 'Réinitialiser'
      end
      expect(page).to have_content 'vous allez recevoir un lien de réinitialisation par email'

      click_reset_password_link_for user.email

      expect(page).to have_content 'Changement de mot de passe'

      fill_in 'user_password', with: new_password
      # fill_in 'user_password_confirmation', with: new_password
      click_on 'Changer le mot de passe'
      expect(page).to have_content('Votre mot de passe a été changé avec succès')
    end
  end
end
