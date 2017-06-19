require 'spec_helper'

feature 'user arrive on siret page' do
  let(:procedure) { create(:procedure, :published) }
  let(:user) { create(:user) }
  let(:siret) { '42149333900020' }
  let(:siren) { siret[0...9] }

  context 'when user is not logged in' do
    before do
      visit new_users_dossiers_path(procedure_id: procedure.id)
    end
    scenario 'he is redirected to login page' do
      expect(page).to have_css('#new_user')
    end
    context 'when he enter login information' do
      before do
        within('#new_user') do
          page.find_by_id('user_email').set user.email
          page.find_by_id('user_password').set user.password
          page.click_on 'Se connecter'
        end
      end
      scenario 'he is redirected to siret page to enter a siret' do
        expect(page).to have_css('#new_siret')
      end
      context 'when enter a siret', js: true do
        before do
          stub_request(:get, "https://api-dev.apientreprise.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/v1/etablissements/exercices/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/v1/associations/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 404, body: '')

          page.find_by_id('dossier-siret').set siret
          page.click_on 'Valider'
        end
        scenario 'he is redirected to recap info entreprise page' do
          wait_for_ajax
          expect(page).to have_css('#recap-info-entreprise')
        end
      end
    end
  end
end
