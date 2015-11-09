require 'spec_helper'

feature 'add a new type de piece justificative', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when create a new procedure' do
    before do
      visit new_admin_procedure_path
    end

    scenario 'page have form to created new type de piece justificative' do
      expect(page).to have_css('#type_de_piece_justificative_0')
      expect(page).to have_css('input[name="procedure[new_type_de_piece_justificative[0]][libelle]"]')
      expect(page).to have_css('textarea[name="procedure[new_type_de_piece_justificative[0]][description]"]')
      expect(page).to have_css('input[name="procedure[new_type_de_piece_justificative[0]][_destroy]"]', visible: false)

      expect(page).to have_css('#new_type_de_piece_justificative #add_type_de_piece_justificative_button')
    end

    context 'when user add a new piece justificative type' do
      before do
        page.find_by_id('procedure_new_type_de_piece_justificative_0__libelle').set 'Libelle de test'
        page.find_by_id('procedure_new_type_de_piece_justificative_0__description').set 'Description de test'
        page.click_on 'add_type_de_piece_justificative_procedure'
      end

      scenario 'a new piece justificative type line is appeared with increment index id' do
        expect(page).to have_css('#type_de_piece_justificative_1')
        expect(page).to have_css('input[name="procedure[new_type_de_piece_justificative[1]][libelle]"]')
        expect(page).to have_css('textarea[name="procedure[new_type_de_piece_justificative[1]][description]"]')
        expect(page).to have_css('input[name="procedure[new_type_de_piece_justificative[1]][_destroy]"]', visible: false)
      end

      scenario 'the first line is filled' do
        expect(page.find_by_id('procedure_new_type_de_piece_justificative_0__libelle').value).to eq('Libelle de test')
        expect(page.find_by_id('procedure_new_type_de_piece_justificative_0__description').value).to eq('Description de test')
      end

      scenario 'the new line is empty' do
        expect(page.find_by_id('procedure_new_type_de_piece_justificative_1__libelle').value).to eq('')
        expect(page.find_by_id('procedure_new_type_de_piece_justificative_1__description').value).to eq('')
        expect(page.find_by_id('procedure_new_type_de_piece_justificative_1___destroy', visible: false).value).to eq('false')
      end

      scenario 'the button Ajouter is at side new line' do
        expect(page).to have_css('#new_type_de_piece_justificative #type_de_piece_justificative_1 #add_type_de_piece_justificative_button')
        expect(page).not_to have_css('#type_de_piece_justificative_0 #add_type_de_piece_justificative_button')
      end
    end
  end
end
