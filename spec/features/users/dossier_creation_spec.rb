require 'spec_helper'

feature 'As a User I wanna create a dossier' do
  let(:user)  { create(:user) }
  let(:siret) { '40307130100044' }
  let(:siren) { siret[0...9] }

  context 'Right after sign_in I shall see inscription by credentials/siret, I can create a new Dossier' do
    let(:procedure_with_siret)     { create(:procedure, :published, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }
    let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }

    context 'Identification for individual' do
      before do
        login_as user, scope: :user
        visit commencer_path(procedure_path: procedure_for_individual.path)
        fill_in 'dossier_individual_attributes_nom',       with: 'Nom'
        fill_in 'dossier_individual_attributes_prenom',    with: 'Prenom'
        find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
      end

      scenario "with a proper date input field for birthdate (type='date' supported)" do
        fill_in 'dossier_individual_attributes_birthdate', with: '1987-10-14'
        page.find_by_id('etape_suivante').click
        expect(page).to have_current_path(users_dossier_carte_path(procedure_for_individual.dossiers.last.id.to_s), only_path: true)
        page.find_by_id('etape_suivante').click
        fill_in "champs_#{procedure_for_individual.dossiers.last.champs.first.id}", with: 'contenu du champ 1'
        page.find_by_id('suivant').click
        expect(user.dossiers.first.individual.birthdate).to eq("1987-10-14")
        expect(page).to have_current_path(users_dossier_recapitulatif_path(procedure_for_individual.dossiers.last.id.to_s), only_path: true)
      end

      scenario "with a basic text input field for birthdate (type='date' unsupported)" do
        fill_in 'dossier_individual_attributes_birthdate', with: '14/10/1987'
        page.find_by_id('etape_suivante').click
        expect(page).to have_current_path(users_dossier_carte_path(procedure_for_individual.dossiers.last.id.to_s), only_path: true)
        page.find_by_id('etape_suivante').click
        fill_in "champs_#{procedure_for_individual.dossiers.last.champs.first.id}", with: 'contenu du champ 1'
        page.find_by_id('suivant').click
        expect(user.dossiers.first.individual.birthdate).to eq("1987-10-14")
        expect(page).to have_current_path(users_dossier_recapitulatif_path(procedure_for_individual.dossiers.last.id.to_s), only_path: true)
      end
    end

    scenario 'Identification through siret', vcr: { cassette_name: 'search_ban_paris' }, js: true do
      login_as user, scope: :user
      visit commencer_path(procedure_path: procedure_with_siret.path)
      expect(page).to have_current_path(users_dossier_path(procedure_with_siret.dossiers.last.id.to_s), only_path: true)
      fill_in 'dossier-siret', with: siret
      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
        .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))
      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
        .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/exercices/#{siret}?token=#{SIADETOKEN}")
        .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/associations/#{siret}?token=#{SIADETOKEN}")
        .to_return(status: 404, body: '')
      page.find_by_id('dossier-siret').set siret
      page.find_by_id('submit-siret').click
      expect(page).to have_css('#recap-info-entreprise')
      find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
      page.find_by_id('etape_suivante').click
      expect(page).to have_current_path(users_dossier_carte_path(procedure_with_siret.dossiers.last.id.to_s), only_path: true)
      page.find_by_id('etape_suivante').click
      fill_in "champs_#{procedure_with_siret.dossiers.last.champs.first.id}", with: 'contenu du champ 1'
      page.find_by_id('suivant').click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(procedure_with_siret.dossiers.last.id.to_s), only_path: true)
    end
  end
end
