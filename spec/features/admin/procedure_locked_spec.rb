require 'spec_helper'

feature 'procedure locked' do

  let(:administrateur) { create(:administrateur) }
  let(:published) { false }
  let(:procedure) { create(:procedure, administrateur: administrateur, published: published) }

  before do
    login_as administrateur, scope: :administrateur
    visit admin_procedure_path(procedure)
  end

  context 'when procedure is not published' do
    scenario 'info label is not present' do
      expect(page).not_to have_content('La procédure ne peut plus être modifiée car elle a été publiée')
    end
  end
  context 'when procedure is published' do
    let(:published) { true }
    before do
      visit admin_procedure_path(procedure)
    end

    scenario 'info label is present' do
      expect(page).to have_content('La procédure ne peut plus être modifiée car elle a été publiée')
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

    context 'when user click on Pieces Justificatives tab' do
      before do
        page.click_on 'Pièces justificatives'
      end

      scenario 'page doest not change' do
        expect(page).to have_css('#procedure_show')
      end
    end
  end
end
