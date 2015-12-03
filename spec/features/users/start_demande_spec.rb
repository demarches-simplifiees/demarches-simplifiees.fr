require 'spec_helper'

feature 'user arrive on siret page' do
  let(:procedure) { create(:procedure) }
  let(:user) { create(:user) }
  let(:siret) { '42149333900020' }
  let(:siren) { siret[0...9] }
  context 'when user is not logged in' do
    before do
      visit new_users_dossiers_path(procedure_id: procedure.id)
    end
    scenario 'he is redirected to login page' do
      expect(page).to have_css('#login_user')
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
        expect(page).to have_css('#pro_section')
      end
      context 'when enter a siret' do
        before do
          stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/entreprises/#{siren}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/exercices/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
          page.find_by_id('dossier_siret').set siret
          page.click_on 'Commencer'
        end
        scenario 'he is redirected to recap info entreprise page' do
          expect(page).to have_css('#recap_info_entreprise')
        end
      end
    end
  end
end