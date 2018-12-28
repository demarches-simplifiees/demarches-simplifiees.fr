require 'spec_helper'
require 'features/admin/procedure_spec_helper'

feature 'As an administrateur I wanna clone a procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:publish_draft, true)
    login_as administrateur, scope: :administrateur
    visit new_from_existing_admin_procedures_path
  end

  context 'Cloning procedure' do
    before 'Create procedure' do
      page.find_by_id('from-scratch').click
      fill_in_dummy_procedure_details
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
