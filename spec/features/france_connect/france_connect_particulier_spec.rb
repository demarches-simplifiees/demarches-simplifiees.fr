require 'spec_helper'

feature 'France Connect Particulier  Connexion' do

  let(:code) { 'plop' }
  let(:given_name) { 'titi' }
  let(:family_name) { 'toto' }
  let(:birthdate) { '20150821' }
  let(:gender) { 'M' }
  let(:birthplace) { '1234' }
  let(:email) { 'plop@plop.com' }
  let(:know_france_connect_particulier_id) { 'blabla' }
  let(:unknow_france_connect_particulier_id) { 'titi' }

  let(:user_info) { Hashie::Mash.new(france_connect_particulier_id: france_connect_particulier_id,
                                     given_name: given_name,
                                     family_name: family_name,
                                     birthdate: birthdate,
                                     birthplace: birthplace,
                                     gender: gender,
                                     email: email) }

  context 'when user is on login page' do

    before do
      visit new_user_session_path
    end

    scenario 'link to France Connect is present' do
      expect(page).to have_css('a#btn_fcp')
    end

    context 'and click on france connect link' do
      let(:code) { 'plop' }

      context 'when authentification is ok' do
        let!(:user) { create(:user,
                             france_connect_particulier_id: know_france_connect_particulier_id,
                             given_name: given_name,
                             family_name: family_name,
                             birthdate: birthdate,
                             birthplace: birthplace,
                             gender: gender) }

        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(user_info)
          page.find_by_id('btn_fcp').click
        end

        context 'when is the first connexion' do
          let(:france_connect_particulier_id) { unknow_france_connect_particulier_id }

          scenario 'he is redirected to france connect particulier page' do
            expect(page).to have_content('Nouvelle connexion')
          end

          context 'when he fill an email and valid' do
            before do
              page.find_by_id('user_email').set email
              page.find_by_id('valid_new_fcp').click
            end

            scenario 'he is redirected to user dossiers page' do
              expect(page).to have_content('Mes dossiers')
            end
          end
        end

        context 'when is not the first connexion' do
          let(:france_connect_particulier_id) { know_france_connect_particulier_id }

          scenario 'he is redirected to user dossiers page' do
            expect(page).to have_content('Mes dossiers')
          end
        end
      end

      context 'when authentification is not ok' do
        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
          page.find_by_id('btn_fcp').click
        end

        scenario 'he is redirected to login page' do
          expect(page).to have_css('a#btn_fcp')
        end

        scenario 'error message is displayed' do
          expect(page).to have_content(I18n.t('errors.messages.france_connect.connexion'))
        end
      end
    end
  end
end