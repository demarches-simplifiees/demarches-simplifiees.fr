require 'spec_helper'

feature 'delete a type de champs form', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when user click on type de champs red X button' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    context 'when user edit a type de champs already save in database' do
      let(:type_de_champs) { procedure.types_de_champs.first }

      before do
        page.click_on 'delete_type_de_champs_0_procedure'
      end

      scenario 'form is mask for the user' do
        expect(page.find_by_id('type_de_champs_0', visible: false).visible?).to be_falsey
      end

      scenario 'delete attribut of type de champs is turn to true' do
        expect(page.find_by_id('type_de_champs_0', visible: false).find_by_id('delete', visible: false).value).to eq('true')
      end
    end

    context 'when user edit a type de champs just add on the form page' do
      before do
        page.click_on 'add_type_de_champs_procedure'
        page.click_on 'add_type_de_champs_procedure'
        page.click_on 'delete_type_de_champs_1_procedure'
        page.click_on 'delete_type_de_champs_2_procedure'
      end

      scenario 'form is mask for the user' do
        expect(page.find_by_id('type_de_champs_1', visible: false).visible?).to be_falsey
        expect(page.find_by_id('type_de_champs_2', visible: false).visible?).to be_falsey
      end

      scenario 'delete attribut of type de champs is turn to true' do
        expect(page.find_by_id('type_de_champs_1', visible: false).find_by_id('delete', visible: false).value).to eq('true')
        expect(page.find_by_id('type_de_champs_2', visible: false).find_by_id('delete', visible: false).value).to eq('true')
      end
    end
  end
end
