# frozen_string_literal: true

describe 'France Connect Particulier Connexion' do
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

  context 'when user is on login page', if: ENV['FC_PARTICULIER_ID'].present? do
    before { visit new_user_session_path }

    scenario 'link to France Connect is present' do
      expect(page).to have_css('.fr-connect')
    end

    context 'and click on france connect link', if: ENV['FC_PARTICULIER_ID'].present? do
      context 'when authentification is ok' do
        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier).and_return(france_connect_information)
        end

        context 'when no user is linked' do
          let(:france_connect_information) { build(:france_connect_information, user_info) }

          context 'and no user has the same email' do
            before {
              page.find('.fr-connect').click
            }

            scenario 'he is redirected to user dossiers page' do
              expect(page).to have_content("Choisissez votre email de contact pour finaliser votre connexion")
              find("#use_france_connect_email_no").click
              fill_in("email", with: "exemple@email.com")
              page.find("input[type='submit'][name='commit'][value='Confirmer']").click
              expect(page).to have_content("Confirmez votre email")
              click_on 'Continuer'
              expect(User.find_by(email: email)).not_to be nil
            end

            scenario 'he can choose not to use FranceConnect email and input an alternative email' do
              expect(page).to have_content("Choisissez votre email de contact pour finaliser votre connexion")

              expect(page).to have_selector("input[name='email']", visible: true, wait: 10)

              fill_in 'email', with: 'alternative@example.com'
              click_on 'Confirmer'

              expect(page).to have_content("Confirmez votre email")
            end
          end

          context 'and an user exists with the same email' do
            let!(:user) { create(:user, email: email, password: SECURE_PASSWORD) }

            before do
              page.find('.fr-connect').click
            end

            scenario 'he is redirected to the merge page' do
              expect(page).to have_content('Fusion des comptes')
            end

            scenario 'it merges its account' do
              page.find('#it-is-mine').click
              fill_in 'password', with: SECURE_PASSWORD
              click_on 'Fusionner les comptes'

              expect(page).to have_content('Dossiers')
            end

            scenario 'it uses another email that belongs to nobody' do
              page.find('#it-is-not-mine').click
              fill_in 'email', with: 'new_email@a.com'
              click_on 'Utiliser ce mail'

              expect(page).to have_content('Nous venons de vous envoyer le mail de confirmation')
            end

            context 'and the user wants an email that belongs to another account', js: true do
              let!(:another_user) { create(:user, email: 'an_existing_email@a.com', password: SECURE_PASSWORD) }

              scenario 'it uses another email that belongs to another account' do
                find('label[for="it-is-not-mine"]').click

                expect(page).to have_css('.new-account', visible: true)

                within '.new-account' do
                  fill_in 'email', with: 'an_existing_email@a.com'
                  click_on 'Utiliser ce mail'
                end

                expect(page).to have_content('Nous venons de vous envoyer le mail de confirmation')
              end
            end
          end
        end

        context 'when a user is linked' do
          let!(:france_connect_information) do
            create(:france_connect_information, :with_user, user_info.merge(created_at: Time.zone.parse('12/12/2012'), updated_at: Time.zone.parse('12/12/2012')))
          end

          before { page.find('.fr-connect').click }

          scenario 'he is redirected to user dossiers page' do
            expect(page).to have_content('Dossiers')
          end

          scenario 'the updated_at date is well updated' do
            expect(france_connect_information.reload.updated_at).not_to eq(france_connect_information.created_at)
          end
        end
      end

      context 'when authentification is not ok' do
        before do
          allow_any_instance_of(FranceConnectParticulierClient).to receive(:authorization_uri).and_return(france_connect_particulier_callback_path(code: code))
          allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
          page.find('.fr-connect').click
        end

        scenario 'he is redirected to login page' do
          expect(page).to have_css('.fr-connect')
        end

        scenario 'error message is displayed' do
          expect(page).to have_content(I18n.t('errors.messages.france_connect.connexion'))
        end
      end
    end
  end
end
