require 'spec_helper'

feature 'on backoffice page' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }
  let(:procedure) { create(:procedure, administrateur: administrateur) }

  let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: 'updated') }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure

    visit backoffice_path
  end

  context 'when gestionnaire is logged in' do
    before do
      page.find_by_id(:gestionnaire_email).set gestionnaire.email
      page.find_by_id(:gestionnaire_password).set gestionnaire.password

      page.click_on 'Se connecter'
    end
    context 'when he click on first dossier' do
      before do
        page.click_on dossier.id
      end

      scenario 'it redirect to dossier page' do
        expect(page).to have_css('#backoffice_dossier_show')
      end
    end

    context 'when gestionnaire have enterprise and individual dossier in his inbox' do
      let!(:procedure_individual) { create :procedure, libelle: 'procedure individual', administrateur: administrateur, for_individual: true }
      let!(:dossier_individual) { create :dossier, procedure: procedure_individual, state: 'updated' }

      before do
        create :assign_to, gestionnaire: gestionnaire, procedure: procedure_individual

        visit backoffice_path
        page.click_on dossier_individual.id
      end

      scenario 'it redirect to dossier page' do
        expect(page).to have_css('#backoffice_dossier_show')
      end
    end
  end
end