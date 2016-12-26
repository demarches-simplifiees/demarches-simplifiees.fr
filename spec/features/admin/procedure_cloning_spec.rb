require 'spec_helper'

feature 'As an administrateur I wanna clone a procedure', js: true do

  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
    visit root_path
  end

  context 'Cloning procedure' do

    before 'Create procedure' do
      page.find_by_id('new-procedure').click
      fill_in 'procedure_libelle', with: 'libelle de la procedure'
      page.execute_script("$('#procedure_description').data('wysihtml5').editor.setValue('description de la procedure')")
      page.find_by_id('save-procedure').click
    end

    scenario 'Cloning' do
      visit admin_procedures_draft_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      page.all('.clone-btn').first.click
      visit admin_procedures_draft_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('2')
    end
  end
end
