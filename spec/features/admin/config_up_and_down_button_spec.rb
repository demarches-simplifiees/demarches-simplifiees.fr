require 'spec_helper'

feature 'config up and down button display', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when procedure have not type de champs' do
    let!(:procedure) { create(:procedure) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    scenario 'type_de_champs_0 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_0_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_0_down_procedure', visible: false).visible?).to be_falsey
    end
  end

  context 'when procedure have one type de champs' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    scenario 'type_de_champs_0 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_0_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_0_down_procedure', visible: false).visible?).to be_falsey
    end

    scenario 'type_de_champs_1 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_1_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_1_down_procedure', visible: false).visible?).to be_falsey
    end
  end

  context 'when procedure have two type de champs' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }
    let!(:type_de_champs) { create(:type_de_champs, procedure: procedure, order_place: 2) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    scenario 'type_de_champs_0 have not up visible and down button visible' do
      expect(page.find_by_id('order_type_de_champs_0_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_0_down_procedure').visible?).to be_truthy
    end

    scenario 'type_de_champs_1 have up button visible and down button not visible' do
      expect(page.find_by_id('order_type_de_champs_1_up_procedure').visible?).to be_truthy
      expect(page.find_by_id('order_type_de_champs_1_down_procedure', visible: false).visible?).to be_falsey
    end

    scenario 'type_de_champs_2 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_2_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_2_down_procedure', visible: false).visible?).to be_falsey
    end
  end

  context 'when procedure have two type de champs into database and one type de champs add to form' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }
    let!(:type_de_champs) { create(:type_de_champs, procedure: procedure, order_place: 2) }

    before do
      visit admin_procedure_path id: procedure.id
      page.click_on 'add_type_de_champs_procedure'
    end

    scenario 'type_de_champs_0 have not up visible and down button visible' do
      expect(page.find_by_id('order_type_de_champs_0_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_0_down_procedure').visible?).to be_truthy
    end

    scenario 'type_de_champs_1 have up button and down button visible' do
      expect(page.find_by_id('order_type_de_champs_1_up_procedure').visible?).to be_truthy
      expect(page.find_by_id('order_type_de_champs_1_down_procedure').visible?).to be_truthy
    end

    scenario 'type_de_champs_2 have up visible and down button not visible' do
      expect(page.find_by_id('order_type_de_champs_2_up_procedure').visible?).to be_truthy
      expect(page.find_by_id('order_type_de_champs_2_down_procedure', visible: false).visible?).to be_falsey
    end

    scenario 'type_de_champs_3 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_3_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_3_down_procedure', visible: false).visible?).to be_falsey
    end
  end

  context 'when procedure have two type de champs into database and one type de champs add to form and delete one type_de_champs' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }
    let!(:type_de_champs) { create(:type_de_champs, procedure: procedure, order_place: 2) }

    before do
      visit admin_procedure_path id: procedure.id
      page.click_on 'add_type_de_champs_procedure'
      page.click_on 'delete_type_de_champs_2_procedure'
    end

    scenario 'type_de_champs_0 have not up visible and down button visible' do
      expect(page.find_by_id('order_type_de_champs_0_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_0_down_procedure').visible?).to be_truthy
    end

    scenario 'type_de_champs_1 have up button visible and down button not visible' do
      expect(page.find_by_id('order_type_de_champs_1_up_procedure').visible?).to be_truthy
      expect(page.find_by_id('order_type_de_champs_1_down_procedure', visible: false).visible?).to be_falsey
    end

    scenario 'type_de_champs_2 have up and down button not visible' do
      expect(page.find_by_id('order_type_de_champs_2_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_2_down_procedure', visible: false).visible?).to be_falsey
    end

    scenario 'type_de_champs_3 have not up and down button visible' do
      expect(page.find_by_id('order_type_de_champs_3_up_procedure', visible: false).visible?).to be_falsey
      expect(page.find_by_id('order_type_de_champs_3_down_procedure', visible: false).visible?).to be_falsey
    end
  end
end