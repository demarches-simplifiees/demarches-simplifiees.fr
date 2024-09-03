# frozen_string_literal: true

describe 'Outdated browsers support:' do
  context 'when the user browser is outdated' do
    before(:each) do
      ie_10_user_agent = 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0; .NET4.0E; .NET4.0C; InfoPath.3)'
      Capybara.page.driver.header('user-agent', ie_10_user_agent)
    end

    scenario 'a banner is displayed' do
      visit new_user_session_path
      expect(page).to have_content('Il n’est plus compatible avec')
      expect(page).to have_content('Votre navigateur internet, Internet Explorer 10, est malheureusement trop ancien')
    end
  end
end
