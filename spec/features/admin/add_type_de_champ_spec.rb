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
      expect(page).to have_css('#type_de_champ_0')
      expect(page).to have_css('input[name="type_de_champ[0][libelle]"]')
      expect(page).to have_css('select[name="type_de_champ[0][type]"]')
      expect(page).to have_css('textarea[name="type_de_champ[0][description]"]')
      expect(page).to have_css('input[name="type_de_champ[0][order_place]"]', visible: false)
      expect(page).to have_css('input[name="type_de_champ[0][id_type_de_champ]"]', visible: false)
      expect(page).to have_css('input[name="type_de_champ[0][delete]"]', visible: false)

      expect(page).to have_css('#order_type_de_champ_0_button', visible: false);
      expect(page).to have_css('#order_type_de_champ_0_up_procedure', visible: false);
      expect(page).to have_css('#order_type_de_champ_0_down_procedure', visible: false);

      expect(page).to have_css('#new_type_de_champ #add_type_de_champ_button')
    end

    context 'when user add a new champs type' do
      before do
        page.find_by_id('type_de_champ_0').find_by_id('libelle').set 'Libelle de test'
        page.find_by_id('type_de_champ_0').find_by_id('description').set 'Description de test'
        page.click_on 'add_type_de_champ_procedure'
      end

      scenario 'a new champs type line is appeared with increment index id' do
        expect(page).to have_css('#type_de_champ_1')
        expect(page).to have_css('input[name="type_de_champ[1][libelle]"]')
        expect(page).to have_css('select[name="type_de_champ[1][type]"]')
        expect(page).to have_css('textarea[name="type_de_champ[1][description]"]')
        expect(page).to have_css('input[name="type_de_champ[1][order_place]"]', visible: false)
        expect(page).to have_css('input[name="type_de_champ[1][id_type_de_champ]"]', visible: false)
        expect(page).to have_css('input[name="type_de_champ[1][delete]"]', visible: false)

        expect(page).to have_css('#order_type_de_champ_1_button', visible: false);
        expect(page).to have_css('#order_type_de_champ_1_up_procedure', visible: false);
        expect(page).to have_css('#order_type_de_champ_1_down_procedure', visible: false);
      end

      scenario 'the first line is filled' do
        expect(page.find_by_id('type_de_champ_0').find_by_id('libelle').value).to eq('Libelle de test')
        expect(page.find_by_id('type_de_champ_0').find_by_id('description').value).to eq('Description de test')
        expect(page.find_by_id('type_de_champ_0').find('input[class="order_place"]', visible: false).value).to eq('1')
      end

      scenario 'the first line have new button delete' do
        expect(page).to have_css('#delete_type_de_champ_0_button')
        expect(page).to have_css('#delete_type_de_champ_0_procedure')
      end

      scenario 'the new line is empty' do
        expect(page.find_by_id('type_de_champ_1').find_by_id('libelle').value).to eq('')
        expect(page.find_by_id('type_de_champ_1').find_by_id('description').value).to eq('')
        expect(page.find_by_id('type_de_champ_1').find('input[class="order_place"]', visible: false).value).to eq('2')
        expect(page.find_by_id('type_de_champ_1').find_by_id('id_type_de_champ', visible: false).value).to eq('')
        expect(page.find_by_id('type_de_champ_1').find_by_id('delete', visible: false).value).to eq('false')
      end

      scenario 'the button Ajouter is at side new line' do
        expect(page).to have_css('#new_type_de_champ #type_de_champ_1 #add_type_de_champ_button')
        expect(page).not_to have_css('#type_de_champ_0 #add_type_de_champ_button')
      end
    end
  end
end
