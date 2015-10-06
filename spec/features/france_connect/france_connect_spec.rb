require 'spec_helper'

feature 'France Connect Connexion' do

  context 'when user is on login page' do

    before do
      visit new_user_session_path
    end

    scenario 'link to France Connect is present' do
      expect(page).to have_css('a#france_connect')
    end

    context 'and click on france connect link' do
      let(:code) { 'plop' }
      before do
        allow_any_instance_of(FranceConnectClient).to receive(:authorization_uri).and_return(france_connect_callback_path(code: code))
        allow(FranceConnectService).to receive(:retrieve_user_informations).and_return(Hashie::Mash.new(email: 'patator@cake.com'))
        page.find_by_id('france_connect').click
      end
      scenario 'he is redirected to france connect' do
        expect(page).to have_content('Vos dossiers')
      end
    end
  end
end