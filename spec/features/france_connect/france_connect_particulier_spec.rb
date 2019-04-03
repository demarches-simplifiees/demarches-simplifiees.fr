require 'spec_helper'

feature 'France Connect Particulier Connexion' do
  let(:code) { 'plop' }
  let(:given_name) { 'titi' }
  let(:family_name) { 'toto' }
  let(:birthdate) { '20150821' }
  let(:gender) { 'M' }
  let(:birthplace) { '1234' }
  let(:email) { 'plop@plop.com' }
  let(:france_connect_particulier_id) { 'blabla' }

  let(:user_info) do
    {
      france_connect_particulier_id: france_connect_particulier_id,
      given_name: given_name,
      family_name: family_name,
      birthdate: birthdate,
      birthplace: birthplace,
      gender: gender,
      email_france_connect: email
    }
  end

  context 'when user is on login page' do
    before do
      visit new_user_session_path
    end

    scenario 'link to France Connect is present' do
      expect(page).to have_css('.france-connect-login-button')
    end

    context 'and click on france connect link' do
      let(:code) { 'plop' }

      context 'when authentification is ok' do
        let(:france_connect_information) do
          create(:france_connect_information,
            france_connect_particulier_id: france_connect_particulier_id,
            given_name: given_name,
            family_name: family_name,
            birthdate: birthdate,
            birthplace: birthplace,
            gender: gender,
            email_france_connect: email)
        end

        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(FranceConnectInformation.new(user_info))
        end

        context 'when is the first connexion' do
          before do
            page.find('.france-connect-login-button').click
          end

          scenario 'he is redirected to user dossiers page' do
            expect(page).to have_content('Dossiers')
          end
        end

        context 'when is not the first connexion' do
          before do
            create(:user, france_connect_information: france_connect_information)
            page.find('.france-connect-login-button').click
          end

          scenario 'he is redirected to user dossiers page' do
            expect(page).to have_content('Dossiers')
          end
        end
      end

      context 'when authentification is not ok' do
        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
          page.find('.france-connect-login-button').click
        end

        scenario 'he is redirected to login page' do
          expect(page).to have_css('.france-connect-login-button')
        end

        scenario 'error message is displayed' do
          expect(page).to have_content(I18n.t('errors.messages.france_connect.connexion'))
        end
      end
    end
  end
end
