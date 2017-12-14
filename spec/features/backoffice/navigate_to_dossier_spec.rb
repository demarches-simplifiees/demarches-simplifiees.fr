require 'spec_helper'

feature 'on backoffice page', js: true do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }
  let(:procedure) { create(:procedure, :published, administrateur: administrateur) }
  let(:procedure_individual) { create :procedure, :published, libelle: 'procedure individual', administrateur: administrateur, for_individual: true }

  let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction') }
  let!(:dossier_individual) { create :dossier, procedure: procedure_individual, state: 'en_construction' }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    create :follow, gestionnaire: gestionnaire, dossier: dossier
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_individual
    create :follow, gestionnaire: gestionnaire, dossier: dossier_individual
    visit users_path
  end

  context 'when gestionnaire is logged in' do
    before do
      page.find_by_id(:user_email).set gestionnaire.email
      page.find_by_id(:user_password).set gestionnaire.password
      page.click_on 'Se connecter'
    end
    context 'when he click on first dossier' do
      before do
        page.find("#tr_dossier_#{dossier.id}", visible: true).click
      end

      scenario 'it redirect to dossier page' do
        expect(page).to have_css('#backoffice-dossier-show')
      end
    end

    context "and goes to the page of a dossier he hasn't access to" do
      let!(:unauthorized_dossier) { create(:dossier, :with_entreprise, state: 'en_construction') }

      before do
        visit backoffice_dossier_path(unauthorized_dossier)
      end

      scenario "it shows an error message" do
        expect(page).to have_content("Le dossier n'existe pas ou vous n'y avez pas accès.")
      end
    end
  end

  context 'when gestionnaire have enterprise and individual dossier in his inbox', js: true do
    before do
      page.find_by_id(:user_email).set gestionnaire.email
      page.find_by_id(:user_password).set gestionnaire.password
      page.click_on 'Se connecter'

      visit backoffice_dossiers_procedure_path(id: procedure_individual.id)
      page.find("#tr_dossier_#{dossier_individual.id}", visible: true).click
    end

    scenario 'it redirect to dossier page' do
      expect(page).to have_css('#backoffice-dossier-show')
    end
  end
end
