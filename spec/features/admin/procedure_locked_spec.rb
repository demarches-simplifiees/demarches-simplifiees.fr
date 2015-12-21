require 'spec_helper'

feature 'procedure locked' do

  let(:administrateur) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: administrateur) }

  before do
    login_as administrateur, scope: :administrateur
    visit admin_procedure_path(procedure)
  end

  context 'when procedure have no file' do
    scenario 'info label is not present' do
      expect(page).not_to have_content('La procédure ne peut plus être modifiée car un usagé a déjà déposé un dossier')
    end
  end
  context 'when procedure have at least a file' do
    before do
      create(:dossier, :with_user, procedure: procedure, state: :initiated)
      visit admin_procedure_path(procedure)
    end

    scenario 'info label is present' do
      expect(page).to have_content('La procédure ne peut plus être modifiée car un usagé a déjà déposé un dossier')
    end

    context 'when user click on Description tab' do
      before do
        page.click_on 'Description'
      end

      scenario 'page doest not change' do
        expect(page).to have_css('#procedure_show')
      end
    end

    context 'when user click on Champs tab' do
      before do
        page.click_on 'Champs'
      end

      scenario 'page doest not change' do
        expect(page).to have_css('#procedure_show')
      end
    end

    context 'when user click on Pieces Justificatiives tab' do
      before do
        page.click_on 'Pièces justificatives'
      end

      scenario 'page doest not change' do
        expect(page).to have_css('#procedure_show')
      end
    end
  end
end
