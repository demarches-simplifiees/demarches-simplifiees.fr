require 'spec_helper'

feature 'user path for dossier creation' do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ) }
  let(:siret) { '53272417600013' }
  let(:siren) { siret[0...9] }

  context 'user arrives on siret page', js: true do
    before do
      visit commencer_path(procedure_path: procedure.path)
    end

    scenario 'he is redirected on login page' do
      expect(page).to have_css('#new_user')
      expect(page).to have_css('.procedure-logos')
      expect(page).to have_content(procedure.libelle)
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
        expect(page).to have_css('#dossier-siret')
      end
      context 'sets siret' do
        before do
          stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
            .to_return(body: File.read('spec/support/files/etablissement.json', status: 200))
          stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
            .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))

          stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/#{siret}?.*token=/)
            .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
          stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/#{siret}?.*token=/)
            .to_return(status: 404, body: '')

          page.find_by_id('dossier-siret').set siret
          page.click_on 'Valider'
        end

        scenario 'user is on page recap info entreprise' do
          expect(page).to have_css('#recap-info-entreprise')
        end

        context 'when user would like change siret' do
          before do
            page.click_on('Changer de SIRET')
          end

          scenario 'redirects to siret page' do
            expect(page).to have_css('#dossier-siret')
          end
        end

        context 'when validating info entreprise recap page' do
          before do
            page.find_by_id('etape_suivante').click
          end
          scenario 'user is on edition page' do
            expect(page).to have_current_path(brouillon_dossier_path(Dossier.last))
          end
          context 'user fill and validate description page' do
            before do
              page.find_by_id("dossier_champs_attributes_0_value").set 'Mon super projet'
              click_on 'Soumettre le dossier'
            end
            scenario 'user is on merci page' do
              expect(page).to have_current_path(merci_dossier_path(Dossier.last))
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
      expect(page).to have_content('La démarche n\'existe pas')
    end
  end
end
