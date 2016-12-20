require 'spec_helper'

feature 'As a User I wanna create a dossier', js: true do

  let(:user)  { create(:user) }
  let(:siret) { '40307130100044' }
  let(:siren) { siret[0...9] }

  context 'Right after sign_in I shall see inscription by credentials/siret, I can create a new Dossier' do
    let(:procedure_with_siret)     { create(:procedure, :published, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }
    let(:procedure_for_individual) { create(:procedure, :published, :for_individual, :with_api_carto, :with_type_de_champ, :with_two_type_de_piece_justificative) }

    scenario 'Identification for individual' do
      login_as user, scope: :user
      visit commencer_path(procedure_path: procedure_for_individual.path)
      fill_in 'dossier_individual_attributes_nom',       with: 'Nom'
      fill_in 'dossier_individual_attributes_prenom',    with: 'Prenom'
      fill_in 'dossier_individual_attributes_birthdate', with: '14/10/1987'
      find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
      page.find_by_id('etape_suivante').click
      expect(page).to have_current_path(users_dossier_carte_path(Dossier.first.id.to_s), only_path: true)
      page.find_by_id('etape_suivante').click
      fill_in 'champs_1', with: 'contenu du champ 1'
      page.find_by_id('suivant').click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
    end

    scenario 'Identification through siret', vcr: {cassette_name: 'search_ban_paris'} do
      login_as user, scope: :user
      visit commencer_path(procedure_path: procedure_with_siret.path)
      expect(page).to have_current_path(users_dossier_path(Dossier.first.id.to_s), only_path: true)
      fill_in 'dossier_siret', with: siret
      stub_request(:get, "https://api-dev.apientreprise.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: 200, body: File.read('spec/support/files/etablissement.json'))
      stub_request(:get, "https://api-dev.apientreprise.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
          .to_return(status: 200, body: File.read('spec/support/files/entreprise.json'))
      stub_request(:get, "https://api-dev.apientreprise.fr/v1/etablissements/exercices/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: 200, body: File.read('spec/support/files/exercices.json'))
      stub_request(:get, "https://api-dev.apientreprise.fr/v1/associations/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: 404, body: '')
      page.find_by_id('dossier_siret').set siret
      page.find_by_id('submit-siret').click
      expect(page).to have_css('#recap_info_entreprise')
      find(:css, "#dossier_autorisation_donnees[value='1']").set(true)
      page.find_by_id('etape_suivante').click
      expect(page).to have_current_path(users_dossier_carte_path(Dossier.first.id.to_s), only_path: true)
      page.find_by_id('etape_suivante').click
      fill_in 'champs_1', with: 'contenu du champ 1'
      page.find_by_id('suivant').click
      expect(page).to have_current_path(users_dossier_recapitulatif_path(Dossier.first.id.to_s), only_path: true)
    end
  end
end
