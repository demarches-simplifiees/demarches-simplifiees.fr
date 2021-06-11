feature 'France Connect Particulier Connexion' do
  before(:all) do
    Flipper.enable("france_connect")
  end

  after(:all) do
    Flipper.disable("france_connect")
  end

  context 'when user comes from a procedure link and choose FranceConnect login' do
    let(:procedure) { create(:procedure, :published, :for_individual, :with_service) }

    before do
      Capybara.current_driver = :mechanize
      allow(SecureRandom).to receive(:hex).with(16).and_return("00000000000000000000000000000000")
    end

    scenario 'he is redirected to dossier page' do
      visit commencer_path(path: procedure.path)

      expect(page).to have_procedure_description(procedure)
      expect(page).to have_css('.france-connect-login-button')

      VCR.use_cassette("france_connect/success/authorize") do
        page.find('.france-connect-login-button').click
      end

      VCR.use_cassette("france_connect/success/call_provider") do
        page.click_on("Démonstration - faible")
      end

      VCR.use_cassette("france_connect/success/interaction") do
        page.fill_in("Identifiant", with: "test")
        page.fill_in("Mot de passe", with: "123")
        page.select("eidas1", from: "acr")
        page.click_on("Valider")
      end

      VCR.use_cassette("france_connect/success/userinfo") do
        VCR.use_cassette("france_connect/success/token") do
          VCR.use_cassette("france_connect/success/confirm_redirect_client", erb: true) do
            page.click_on("Continuer")
          end
        end
      end

      expect(page).to have_procedure_description(procedure)
      expect(page).to have_link("Commencer la démarche")
    end
  end

  context 'when user is on login page and choose FranceConnect login' do
    before do
      Capybara.current_driver = :mechanize
      allow(SecureRandom).to receive(:hex).with(16).and_return("00000000000000000000000000000000")
    end

    context 'when authentication is ok' do
      context 'and it is the first connexion' do
        scenario 'he is redirected to user dossiers page' do
          visit new_user_session_path

          expect(page).to have_css('.france-connect-login-button')

          VCR.use_cassette("france_connect/success/authorize") do
            page.find('.france-connect-login-button').click
          end

          VCR.use_cassette("france_connect/success/call_provider") do
            page.click_on("Démonstration - faible")
          end

          VCR.use_cassette("france_connect/success/interaction") do
            page.fill_in("Identifiant", with: "test")
            page.fill_in("Mot de passe", with: "123")
            page.select("eidas1", from: "acr")
            page.click_on("Valider")
          end

          VCR.use_cassette("france_connect/success/userinfo") do
            VCR.use_cassette("france_connect/success/token") do
              VCR.use_cassette("france_connect/success/confirm_redirect_client", erb: true) do
                page.click_on("Continuer")
              end
            end
          end

          expect(page).to have_content('Dossiers')
        end
      end

      context 'and it is not the first connexion' do
        let!(:fci) { create(:france_connect_information, :with_user) }

        scenario 'he is redirected to user dossiers page' do
          visit new_user_session_path

          expect(page).to have_css('.france-connect-login-button')

          VCR.use_cassette("france_connect/success/authorize") do
            page.find('.france-connect-login-button').click
          end

          VCR.use_cassette("france_connect/success/call_provider") do
            page.click_on("Démonstration - faible")
          end

          VCR.use_cassette("france_connect/success/interaction") do
            page.fill_in("Identifiant", with: "test")
            page.fill_in("Mot de passe", with: "123")
            page.select("eidas1", from: "acr")
            page.click_on("Valider")
          end

          VCR.use_cassette("france_connect/success/userinfo") do
            VCR.use_cassette("france_connect/success/token") do
              VCR.use_cassette("france_connect/success/confirm_redirect_client", erb: true) do
                page.click_on("Continuer")
              end
            end
          end

          expect(page).to have_content('Dossiers')
          expect(fci.reload.updated_at).not_to eq(fci.created_at)
        end
      end
    end

    context 'when authentication code is invalid' do
      scenario 'is redirected to login page with error message' do
        visit new_user_session_path

        expect(page).to have_css('.france-connect-login-button')

        VCR.use_cassette("france_connect/success/authorize") do
          page.find('.france-connect-login-button').click
        end

        VCR.use_cassette("france_connect/success/call_provider") do
          page.click_on("Démonstration - faible")
        end

        VCR.use_cassette("france_connect/success/interaction") do
          page.fill_in("Identifiant", with: "test")
          page.fill_in("Mot de passe", with: "123")
          page.select("eidas1", from: "acr")
          page.click_on("Valider")
        end

        VCR.use_cassette("france_connect/error/token") do
          VCR.use_cassette("france_connect/success/confirm_redirect_client", erb: true) do
            page.click_on("Continuer")
          end
        end

        expect(page).to have_css('.france-connect-login-button')
        expect(page).to have_content(I18n.t('errors.messages.france_connect.connexion'))
      end
    end
  end
end
