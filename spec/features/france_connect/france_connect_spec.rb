require 'spec_helper'

feature 'France Connect Connexion' do

  context 'when user is on login page' do

    before do
      visit new_user_session_path
    end

    scenario 'link to France Connect is present' do
      expect(page).to have_css('a#france_connect')
    end

  end
end