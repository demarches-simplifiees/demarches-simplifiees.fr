feature 'new look banner' do
  context 'when flipper new look is enabled' do
    before(:each) do
      Flipper.enable(:new_look_banner)
    end

    NEW_LOOK = "Mes-Démarches change bientôt d'apparence"

    scenario 'a banner is displayed' do
      visit new_user_session_path
      expect(page).to have_content(NEW_LOOK)
    end

    scenario 'the banner can be dismissed' do
      visit new_user_session_path
      expect(page).to have_content(NEW_LOOK)

      # The banner is hidden immediately
      within '#new-look-banner' do
        click_on 'Cacher'
      end
      expect(page).not_to have_content(NEW_LOOK)
      expect(page).to have_current_path(new_user_session_path)

      # The banner is hidden after a refresh
      page.refresh
      expect(page).not_to have_content(NEW_LOOK)
    end
  end
end
