require 'spec_helper'

feature 'add a new type de champs', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when create a new procedure' do
    before do
      visit new_admin_procedure_path
    end

    scenario 'page have form to created new type de champs' do
      expect(page).to have_css('#type_de_champs_0')
      expect(page).to have_css('input[name="type_de_champs[0][libelle]"]')
      expect(page).to have_css('select[name="type_de_champs[0][type]"]')
      expect(page).to have_css('textarea[name="type_de_champs[0][description]"]')
      expect(page).to have_css('input[name="type_de_champs[0][order_place]"]', visible: false)
      expect(page).to have_css('input[name="type_de_champs[0][id_type_de_champs]"]', visible: false)
      expect(page).to have_css('input[name="type_de_champs[0][delete]"]', visible: false)

      expect(page).to have_css('#new_type_de_champs #add_type_de_champs_button')
    end

    context 'when user add a new champs type' do
      before do
        page.find_by_id('type_de_champs_0').find_by_id('libelle').set 'Libelle de test'
        page.find_by_id('type_de_champs_0').find_by_id('description').set 'Description de test'
        page.click_on 'Ajouter'
      end

      scenario 'a new champs type line is appeared with increment index id' do
        expect(page).to have_css('#type_de_champs_1')
        expect(page).to have_css('input[name="type_de_champs[1][libelle]"]')
        expect(page).to have_css('select[name="type_de_champs[1][type]"]')
        expect(page).to have_css('textarea[name="type_de_champs[1][description]"]')
        expect(page).to have_css('input[name="type_de_champs[1][order_place]"]', visible: false)
        expect(page).to have_css('input[name="type_de_champs[1][id_type_de_champs]"]', visible: false)
        expect(page).to have_css('input[name="type_de_champs[1][delete]"]', visible: false)
      end

      scenario 'the first line is filled' do
        expect(page.find_by_id('type_de_champs_0').find_by_id('libelle').value).to eq('Libelle de test')
        expect(page.find_by_id('type_de_champs_0').find_by_id('description').value).to eq('Description de test')
        expect(page.find_by_id('type_de_champs_0').find_by_id('order_place', visible: false).value).to eq('1')
      end

      scenario 'the new line is empty' do
        expect(page.find_by_id('type_de_champs_1').find_by_id('libelle').value).to eq('')
        expect(page.find_by_id('type_de_champs_1').find_by_id('description').value).to eq('')
        expect(page.find_by_id('type_de_champs_1').find_by_id('order_place', visible: false).value).to eq('2')
        expect(page.find_by_id('type_de_champs_1').find_by_id('id_type_de_champs', visible: false).value).to eq('')
        expect(page.find_by_id('type_de_champs_1').find_by_id('delete', visible: false).value).to eq('false')
      end

      scenario 'the button Ajouter is at side new line' do
        expect(page).to have_css('#new_type_de_champs #type_de_champs_1 #add_type_de_champs_button')
        expect(page).not_to have_css('#type_de_champs_0 #add_type_de_champs_button')
      end
    end
  end
end
