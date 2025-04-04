# frozen_string_literal: true

describe 'France Connect Connexion' do
  let(:code) { 'plop' }
  let(:state) { 'state' }
  let(:id_token) { 'id_token' }
  let(:given_name) { 'titi' }
  let(:family_name) { 'toto' }
  let(:birthdate) { '20150821' }
  let(:gender) { 'M' }
  let(:birthplace) { '1234' }
  let(:fc_email) { 'plop@plop.com' }
  let(:france_connect_particulier_id) { 'blabla' }

  let(:user_info) do
    {
      france_connect_particulier_id: france_connect_particulier_id,
      given_name: given_name,
      family_name: family_name,
      birthdate: birthdate,
      birthplace: birthplace,
      gender: gender,
      email_france_connect: fc_email
    }
  end

  context 'when user is on login page' do
    before do
      allow(FranceConnectService).to receive(:enabled?).and_return(true)
      visit new_user_session_path
    end

    scenario 'link to France Connect is present' do
      expect(page).to have_css('.fr-connect')
    end

    context 'and click on france connect link' do
      context 'when authentification is ok' do
        before do
          allow(FranceConnectService).to receive(:authorization_uri)
            .and_return([france_connect_callback_path(code:, state:), state, 'nonce'])

          allow(FranceConnectService).to receive(:retrieve_user_informations)
            .and_return([france_connect_information, id_token])
        end

        context 'when no user is linked' do
          let(:france_connect_information) { build(:france_connect_information, user_info) }

          context 'and no user has the same email' do
            before do
              page.find('.fr-connect').click
            end

            scenario 'he is redirected to user dossiers page', js: true do
              expect(page).to have_content("Choisissez votre adresse électronique de contact pour finaliser votre connexion")

              find('label', text: "Oui, utiliser #{fc_email} comme adresse électronique de contact").click

              click_on 'Valider'
              expect(User.find_by(email: fc_email).email_verified_at).to be_present
            end

            scenario 'he can choose not to use FranceConnect email and input an alternative email', js: true do
              alternative_email = 'alternative@example.com'

              expect(page).to have_content("Choisissez votre adresse électronique de contact pour finaliser votre connexion")
              find('label', text: 'utiliser une autre adresse').click

              expect(page).to have_selector("input[name='email']", visible: true, wait: 10)

              fill_in 'email', with: alternative_email
              click_on 'Valider'

              expect(page).to have_content('Nous venons de vous envoyer le mail de confirmation')
              expect(User.find_by(email: alternative_email)).to be_nil

              perform_enqueued_jobs

              confirmation_email = open_email(alternative_email)
              link = confirmation_email.body.match(/href="[^"]*(\/france_connect\/merge_using_email_link.*?)"/)[1]

              visit link

              expect(page).to have_content('Les comptes FranceConnect et demarches-simplifiees.fr sont à présent fusionnés')
              expect(page).to have_content(alternative_email)

              expect(User.find_by(email: alternative_email).email_verified_at).to be_present
            end
          end

          context 'and an user exists with the same email' do
            let!(:user) { create(:user, email: fc_email, password: SECURE_PASSWORD) }

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
              click_on 'Utiliser cette adresse électronique'

              expect(page).to have_content('Nous venons de vous envoyer le mail de confirmation')
            end

            context 'and the user wants an email that belongs to another account', js: true do
              let!(:another_user) { create(:user, email: 'an_existing_email@a.com', password: SECURE_PASSWORD) }

              scenario 'it uses another email that belongs to another account' do
                find('label[for="it-is-not-mine"]').click

                expect(page).to have_css('.new-account', visible: true)

                within '.new-account' do
                  fill_in 'email', with: 'an_existing_email@a.com'
                  click_on 'Utiliser cette adresse électronique'
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
          allow(FranceConnectService).to receive(:enabled?).and_return(true)
          allow(FranceConnectService).to receive(:authorization_uri).and_return(france_connect_callback_path(code:, state:), state, 'nonce')
          allow(FranceConnectService).to receive(:retrieve_user_informations) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
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
