require 'spec_helper'

feature 'delete a type de champs form', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when user click on type de trash button' do
    let!(:procedure) { create(:procedure, :with_type_de_champ) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    context 'when user edit a type de champs already save in database' do
      let(:type_de_champ) { procedure.types_de_champ.first }

      before do
        page.click_on 'delete_type_de_champ_1_procedure'
      end

      scenario 'form is mask for the user' do
        expect(page.find_by_id('type_de_champ_1', visible: false).visible?).to be_falsey
      end

      scenario 'delete attribut of type de champs is turn to true' do
        expect(page.find_by_id('type_de_champ_1', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
      end

      scenario 'attribut node is to move into div liste_delete_champ' do
        expect(page).to have_css('#liste_delete_champ #type_de_champ_1', visible: false)
      end
    end

    context 'when user edit a type de champs just add on the form page' do
      before do
        page.click_on 'add_type_de_champ_procedure'
        page.click_on 'add_type_de_champ_procedure'
        page.click_on 'add_type_de_champ_procedure'
        page.click_on 'add_type_de_champ_procedure'
        page.click_on 'add_type_de_champ_procedure'
        page.click_on 'delete_type_de_champ_2_procedure'
        page.click_on 'delete_type_de_champ_3_procedure'
      end

      scenario 'form is mask for the user' do
        expect(page.find_by_id('type_de_champ_2', visible: false).visible?).to be_falsey
        expect(page.find_by_id('type_de_champ_3', visible: false).visible?).to be_falsey
      end

      scenario 'delete attribut of type de champs is turn to true' do
        expect(page.find_by_id('type_de_champ_2', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
        expect(page.find_by_id('type_de_champ_3', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
      end

      scenario 'attribut node is to move into div liste_delete_champ' do
        expect(page).to have_css('#liste_delete_champ #type_de_champ_2', visible: false)
        expect(page).to have_css('#liste_delete_champ #type_de_champ_3', visible: false)
      end

      scenario 'order_place type_de_champ_1_procedure is 1' do
        expect(page.find_by_id('type_de_champ_1').find("input[class='order_place']", visible: false).value).to eq('1')
      end

      scenario 'order_place type_de_champ_4_procedure is 2' do
        expect(page.find_by_id('type_de_champ_4').find("input[class='order_place']", visible: false).value).to eq('2')
      end

      scenario 'order_place type_de_champ_5_procedure is 3' do
        expect(page.find_by_id('type_de_champ_5').find("input[class='order_place']", visible: false).value).to eq('3')
      end

      scenario 'order_place type_de_champ_6_procedure is 4' do
        expect(page.find_by_id('type_de_champ_6').find("input[class='order_place']", visible: false).value).to eq('4')
      end
    end
  end
end
