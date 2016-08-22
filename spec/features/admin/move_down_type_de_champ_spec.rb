require 'spec_helper'

feature 'move down button type de champs', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  let(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:type_de_champ_0) { create(:type_de_champ_public, procedure: procedure, order_place: 0) }
  let!(:type_de_champ_1) { create(:type_de_champ_public, procedure: procedure, order_place: 1) }
  let!(:type_de_champ_2) { create(:type_de_champ_public, procedure: procedure, order_place: 2) }
  let!(:type_de_champ_3) { create(:type_de_champ_public, procedure: procedure, order_place: 3) }

  context 'when clicking on move down for type de champ 1' do
    before do
      visit admin_procedure_types_de_champ_path procedure.id
      page.find_by_id('btn_down_1').click
      wait_for_ajax
      type_de_champ_1.reload
      type_de_champ_2.reload
    end
    scenario 'it switches type_de_champ 1 and 2 place ' do
      expect(type_de_champ_1.order_place).to eq(2)
      expect(type_de_champ_2.order_place).to eq(1)
    end
  end
end
