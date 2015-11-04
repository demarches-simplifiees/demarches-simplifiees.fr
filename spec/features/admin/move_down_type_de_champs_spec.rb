require 'spec_helper'

feature 'move down button type de champs', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end

  context 'when click on move down type de champs button' do
    let!(:procedure) { create(:procedure, :with_type_de_champs) }
    let!(:type_de_champs) { create(:type_de_champs, procedure: procedure, order_place: 2) }

    before do
      visit admin_procedure_path id: procedure.id
    end

    context 'when procedure have two type de champs' do
      before do
        page.click_on 'order_type_de_champs_0_down_procedure'
      end

      scenario 'it inverse the twice type de champs' do
        expect(page.find_by_id('type_de_champs_0').find('input[class="order_place"]', visible: false).value).to eq('2');
        expect(page.find_by_id('type_de_champs_1').find('input[class="order_place"]', visible: false).value).to eq('1');
      end
    end

    context 'when procedure have two type de champs in database and 3 type de champs add on the page' do
      before do
        page.click_on 'add_type_de_champs_procedure'
        page.click_on 'add_type_de_champs_procedure'
        page.click_on 'add_type_de_champs_procedure'
      end

      context 'when to click on down_button type_de_champs_1' do
        before do
          page.click_on 'order_type_de_champs_1_down_procedure'
        end

        scenario 'type_de_champs_1 and type_de_champs_2 is reversed' do
          expect(page.find_by_id('type_de_champs_0').find('input[class="order_place"]', visible: false).value).to eq('1');
          expect(page.find_by_id('type_de_champs_2').find('input[class="order_place"]', visible: false).value).to eq('2');
          expect(page.find_by_id('type_de_champs_1').find('input[class="order_place"]', visible: false).value).to eq('3');
          expect(page.find_by_id('type_de_champs_3').find('input[class="order_place"]', visible: false).value).to eq('4');
          expect(page.find_by_id('type_de_champs_4').find('input[class="order_place"]', visible: false).value).to eq('5');
        end

        context 'when to click on up_button type_de_champs_3' do
          before do
            page.click_on 'order_type_de_champs_3_down_procedure'
          end

          scenario 'type_de_champs_3 and type_de_champs_4 is reversed' do
            expect(page.find_by_id('type_de_champs_0').find('input[class="order_place"]', visible: false).value).to eq('1');
            expect(page.find_by_id('type_de_champs_2').find('input[class="order_place"]', visible: false).value).to eq('2');
            expect(page.find_by_id('type_de_champs_1').find('input[class="order_place"]', visible: false).value).to eq('3');
            expect(page.find_by_id('type_de_champs_4').find('input[class="order_place"]', visible: false).value).to eq('4');
            expect(page.find_by_id('type_de_champs_3').find('input[class="order_place"]', visible: false).value).to eq('5');
          end

          context 'when to click on up_button type_de_champs_0' do
            before do
              page.click_on 'order_type_de_champs_0_down_procedure'
            end

            scenario 'type_de_champs_0 and type_de_champs_2 is reversed' do
              expect(page.find_by_id('type_de_champs_2').find('input[class="order_place"]', visible: false).value).to eq('1');
              expect(page.find_by_id('type_de_champs_0').find('input[class="order_place"]', visible: false).value).to eq('2');
              expect(page.find_by_id('type_de_champs_1').find('input[class="order_place"]', visible: false).value).to eq('3');
              expect(page.find_by_id('type_de_champs_4').find('input[class="order_place"]', visible: false).value).to eq('4');
              expect(page.find_by_id('type_de_champs_3').find('input[class="order_place"]', visible: false).value).to eq('5');
            end
          end
        end
      end
    end
  end
end
