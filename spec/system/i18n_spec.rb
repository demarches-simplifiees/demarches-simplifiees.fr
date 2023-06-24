describe 'Accessing the website in different languages:' do
  context 'when the i18n feature-flag is enabled' do
    before { ENV['LOCALIZATION_ENABLED'] = 'true' }
    after { ENV['LOCALIZATION_ENABLED'] = 'false' }

    scenario 'I can change the language of the page' do
      visit new_user_session_path
<<<<<<< HEAD
      expect(page).to have_text('Si vous avez')
=======
      expect(page).to have_text("Connexion à #{APPLICATION_NAME}")
>>>>>>> 580437234381fa07f17c32d1833ee7b0d1be947d

      find('.fr-translate__btn').click
      find('.fr-nav__link[hreflang="en"]').click

      # The page is now in English
      expect(page).to have_text('If you already have')
      # The page URL stayed the same
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
