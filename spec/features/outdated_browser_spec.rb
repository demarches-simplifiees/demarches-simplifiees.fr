feature 'Outdated browsers support:' do
  context 'when the user browser is outdated' do
    before(:each) do
      ie_10_user_agent = 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0; .NET4.0E; .NET4.0C; InfoPath.3)'
      Capybara.page.driver.header('user-agent', ie_10_user_agent)
    end

    scenario 'a banner is displayed' do
      visit new_user_session_path
      expect(page).to have_content('Internet Explorer 10 est trop ancien')
    end

    scenario 'the banner can be dismissed' do
      visit new_user_session_path
      expect(page).to have_content('Internet Explorer 10 est trop ancien')

      # The banner is hidden immediately
      within '#outdated-browser-banner' do
        click_on 'Ignorer'
      end
      expect(page).not_to have_content('Internet Explorer 10 est trop ancien')
      expect(page).to have_current_path(new_user_session_path)

      # The banner is hidden after a refresh
      page.refresh
      expect(page).not_to have_content('Internet Explorer 10 est trop ancien')
    end
  end

  context 'when the user browser is about to be outdated' do
    before(:each) do
      ie_11_user_agent = 'Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko'
      Capybara.page.driver.header('user-agent', ie_11_user_agent)
    end

    scenario 'IE11 gets a dedicated depreciation banner for update before jan 31st 2021' do
      visit new_user_session_path
      expect(page).to have_content('31 janvier 2021')
      expect(page).to have_content('Internet Explorer 11 est un navigateur trop ancien')

      within '#outdated-browser-banner' do
        click_on 'Ignorer'
      end

      page.refresh
      expect(page).not_to have_content('Internet Explorer 11 est un navigateur trop ancien')
    end
  end
end
