require 'spec_helper'

feature 'user path for dossier creation' do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published) }
  let(:siret) { '53272417600013' }
  let(:siren) { siret[0...9] }

  context 'user arrives on siret page' do
    before do
      visit new_users_dossiers_path(procedure_id: procedure.id)
    end

    scenario 'he is redirected on login page' do
      expect(page).to have_css('#login_user')
    end

    context 'user sign_in' do
      before do
        within('#new_user') do
          page.find_by_id('user_email').set user.email
          page.find_by_id('user_password').set user.password
          page.click_on 'Se connecter'
        end
      end
      scenario 'redirects to siret page' do
        expect(page).to have_css('#dossier_siret')
      end
      context 'sets siret' do
        before do
          stub_request(:get, "https://api-dev.apientreprise.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
              .to_return(body: File.read('spec/support/files/etablissement.json', status: 200))
          stub_request(:get, "https://api-dev.apientreprise.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))

          stub_request(:get, "https://api-dev.apientreprise.fr/v1/etablissements/exercices/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
          stub_request(:get, "https://api-dev.apientreprise.fr/v1/associations/#{siret}?token=#{SIADETOKEN}")
              .to_return(status: 404, body: '')

          page.find_by_id('dossier_siret').set siret
          page.click_on 'Commencer'
        end
        scenario 'user is on page recap info entreprise' do
          expect(page).to have_css('#recap_info_entreprise')
        end
        context 'when validating info entreprise recap page' do
          before do
            page.check('dossier_autorisation_donnees')
            page.click_on 'Etape suivante'
          end
          scenario 'user is on description page' do
            expect(page).to have_css('#description_page')
          end
          context 'user fill and validate description page' do
            before do
              page.find_by_id('nom_projet').set 'Mon super projet'
              page.find_by_id('description').set 'Ma super description'
              page.click_on 'Soumettre mon dossier'
            end
            scenario 'user is on recap page' do
              expect(page).to have_css('#recap_dossier')
            end
          end
        end
      end
    end
  end

  context 'user cannot access non-published procedures' do
    let(:procedure) { create(:procedure) }
    before do
      visit new_users_dossiers_path(procedure_id: procedure.id)
    end

    scenario 'user is on home page', vcr: { cassette_name: 'complete_demande_spec' } do
      expect(page).to have_content('La procédure n\'existe pas')
    end
  end
end