require 'spec_helper'

feature 'on backoffice page' do
  let(:procedure) { create(:procedure) }
  let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }
  before do
    visit backoffice_path
  end
  context 'when gestionnaire is logged in' do
    let(:gestionnaire) { create(:gestionnaire) }
    before do
      page.find_by_id(:gestionnaire_email).set  gestionnaire.email
      page.find_by_id(:gestionnaire_password).set  gestionnaire.password
      page.click_on 'Se connecter'
    end
    context 'when he click on first dossier' do
      before do
        page.click_on dossier.nom_projet
      end
      scenario 'it redirect to dossier page' do
        expect(page).to have_css('#backoffice_dossier_show')
      end
    end
  end
end