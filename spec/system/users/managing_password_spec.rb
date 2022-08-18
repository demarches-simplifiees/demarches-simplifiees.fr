describe 'Managing password:', js: true do
  context 'for simple users' do
    let(:user) { create(:user) }
    let(:new_password) { 'a simple password' }

    scenario 'a simple user can reset their password' do
      visit root_path
      within('.fr-header .fr-container .fr-header__tools .fr-btns-group') do
        click_on 'Connexion'
      end
      click_on 'Mot de passe oublié ?'
      expect(page).to have_current_path(new_user_password_path)

      fill_in 'Email', with: user.email
      perform_enqueued_jobs do
        click_on 'Demander un nouveau mot de passe'
      end
      expect(page).to have_text 'Nous vous avons envoyé un email'
      expect(page).to have_text user.email

      click_reset_password_link_for user.email
      expect(page).to have_content 'Changement de mot de passe'

      fill_in 'user_password', with: new_password
      fill_in 'user_password_confirmation', with: new_password
      click_on 'Changer le mot de passe'
      expect(page).to have_content('Votre mot de passe a bien été modifié.')
    end
  end

  context 'for admins' do
    let(:administrateur) { create(:administrateur) }
    let(:user) { administrateur.user }
    let(:weak_password) { '12345678' }
    let(:strong_password) { 'a new, long, and complicated password!' }

    scenario 'an admin can reset their password', js: true do
      visit root_path
      within('.fr-header .fr-container .fr-header__tools .fr-btns-group') do
        click_on 'Connexion'
      end
      click_on 'Mot de passe oublié ?'
      expect(page).to have_current_path(new_user_password_path)

      fill_in 'Email', with: user.email
      perform_enqueued_jobs do
        click_on 'Demander un nouveau mot de passe'
      end
      expect(page).to have_text 'Nous vous avons envoyé un email'
      expect(page).to have_text user.email

      click_reset_password_link_for user.email

      expect(page).to have_content 'Changement de mot de passe'

      fill_in 'user_password', with: weak_password
      fill_in 'user_password_confirmation', with: weak_password
      expect(page).to have_text('Mot de passe très vulnérable')
      expect(page).to have_button('Changer le mot de passe', disabled: true)

      fill_in 'user_password', with: strong_password
      fill_in 'user_password_confirmation', with: strong_password
      expect(page).to have_text('Mot de passe suffisamment fort et sécurisé')
      expect(page).to have_button('Changer le mot de passe', disabled: false)

      click_on 'Changer le mot de passe'
      expect(page).to have_content('Votre mot de passe a bien été modifié.')
    end
  end

  context 'for super-admins' do
    let(:super_admin) { create(:super_admin) }
    let(:weak_password) { '12345678' }
    let(:strong_password) { 'a new, long, and complicated password!' }

    scenario 'a super-admin can reset their password', js: true do
      visit manager_root_path
      click_on 'Mot de passe oublié'
      expect(page).to have_current_path(new_super_admin_password_path)

      fill_in 'Email', with: super_admin.email
      perform_enqueued_jobs do
        click_on 'Demander un nouveau mot de passe'
      end
      expect(page).to have_text 'vous recevrez un lien vous permettant de récupérer votre mot de passe'

      click_reset_password_link_for super_admin.email

      expect(page).to have_content 'Changement de mot de passe'

      fill_in 'super_admin_password', with: weak_password
      fill_in 'super_admin_password_confirmation', with: weak_password
      expect(page).to have_text('Mot de passe très vulnérable')
      expect(page).to have_button('Changer le mot de passe', disabled: true)

      fill_in 'super_admin_password', with: strong_password
      fill_in 'super_admin_password_confirmation', with: strong_password
      expect(page).to have_text('Mot de passe suffisamment fort et sécurisé')
      expect(page).to have_button('Changer le mot de passe', disabled: false)

      click_on 'Changer le mot de passe'
      expect(page).to have_content('Votre mot de passe a bien été modifié.')
    end
  end

  scenario 'the password reset token has expired' do
    visit edit_user_password_path(reset_password_token: 'invalid-password-token')
    expect(page).to have_content 'Changement de mot de passe'

    fill_in 'user_password', with: 'SomePassword'
    fill_in 'user_password_confirmation', with: 'SomePassword'
    click_on 'Changer le mot de passe'
    expect(page).to have_content('Votre lien de nouveau mot de passe a expiré')
  end
end
