require 'spec_helper'

feature 'As a User I wanna create a dossier' do
  let(:user)  { create(:user) }
  let(:siret) { '40307130100044' }
  let(:siren) { siret[0...9] }

  context 'Right after sign_in I shall see inscription by credentials/siret, I can create a new Dossier' do
    let(:procedure_with_siret)     { create(:procedure, :published, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }
    let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative, ask_birthday: ask_birthday) }

    context 'Identification for individual' do
      before do
        login_as user, scope: :user
        visit commencer_path(procedure_path: procedure_for_individual.path)
        fill_in 'individual_nom',       with: 'Nom'
        fill_in 'individual_prenom',    with: 'Prenom'
      end

      context "when birthday is asked" do
        let(:ask_birthday) { true }

        scenario "with a proper date input field for birthdate (type='date' supported)" do
          fill_in 'individual_birthdate', with: '1987-10-14'
          click_button('Continuer')

          expect(page).to have_current_path(users_dossier_carte_path(procedure_for_individual.dossiers.last.id))
          click_button('Etape suivante')

          expect(page).to have_current_path(brouillon_dossier_path(procedure_for_individual.dossiers.last))

          expect(user.dossiers.first.individual.birthdate).to eq(Date.new(1987, 10, 14))
        end

        scenario "with a basic text input field for birthdate (type='date' unsupported)" do
          fill_in 'individual_birthdate', with: '14/10/1987'
          click_button('Continuer')

          expect(page).to have_current_path(users_dossier_carte_path(procedure_for_individual.dossiers.last.id.to_s))
          click_button('Etape suivante')

          expect(page).to have_current_path(brouillon_dossier_path(procedure_for_individual.dossiers.last))

          expect(user.dossiers.first.individual.birthdate).to eq(Date.new(1987, 10, 14))
        end
      end

      context "when birthday is not asked" do
        let(:ask_birthday) { false }

        scenario "no need for birthday" do
          click_button('Continuer')

          expect(page).to have_current_path(users_dossier_carte_path(procedure_for_individual.dossiers.last))
          click_button('Etape suivante')

          expect(page).to have_current_path(brouillon_dossier_path(procedure_for_individual.dossiers.last))

          expect(user.dossiers.first.individual.birthdate).to eq(nil)
        end
      end
    end

    scenario 'Identification through siret', vcr: { cassette_name: 'api_adresse_search_paris_3' }, js: true do
      login_as user, scope: :user
      visit commencer_path(procedure_path: procedure_with_siret.path)
      expect(page).to have_current_path(users_dossier_path(procedure_with_siret.dossiers.last.id.to_s))

      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
        .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/#{siret}?.*token=/)
        .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/#{siret}?.*token=/)
        .to_return(status: 404, body: '')

      page.find_by_id('dossier-siret').set siret
      click_on 'Valider'
      wait_for_ajax

      expect(page).to have_css('#recap-info-entreprise')
      click_on 'Etape suivante'
      expect(page).to have_current_path(users_dossier_carte_path(procedure_with_siret.dossiers.last.id.to_s))
      click_on 'Etape suivante'
      expect(page).to have_current_path(brouillon_dossier_path(procedure_with_siret.dossiers.last))
    end
  end
end
