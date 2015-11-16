require 'spec_helper'

# feature 'move up and down button type de champs', js: true do
#   let(:administrateur) { create(:administrateur) }

#   before do
#     login_as administrateur, scope: :administrateur
#   end

#   context 'when click on move up and down type de champs button' do
#     let!(:procedure) { create(:procedure, :with_type_de_champ) }
#     let!(:type_de_champ) { create(:type_de_champ, procedure: procedure, order_place: 2) }

#     before do
#       visit admin_procedure_path id: procedure.id
#     end

#     context 'when procedure have two type de champs in database and 3 type de champs add on the page' do
#       before do
#         page.click_on 'add_type_de_champ_procedure'
#         page.click_on 'add_type_de_champ_procedure'
#         page.click_on 'add_type_de_champ_procedure'
#       end
#   #
#       context 'when to click on up_button type_de_champ_2 and down_button type_de_champ_1' do
#         before do
#           page.click_on 'order_type_de_champ_2_up_procedure'
#           page.click_on 'order_type_de_champ_1_down_procedure'
#         end

#         scenario 'type_de_champ_1 is at order place 3 and type_de_champ_2 is at order place 1 ' do
#           expect(page.find_by_id('type_de_champ_2').find('input[class="order_place"]', visible: false).value).to eq('1');
#           expect(page.find_by_id('type_de_champ_3').find('input[class="order_place"]', visible: false).value).to eq('2');
#           expect(page.find_by_id('type_de_champ_1').find('input[class="order_place"]', visible: false).value).to eq('3');
#           expect(page.find_by_id('type_de_champ_4').find('input[class="order_place"]', visible: false).value).to eq('4');
#           expect(page.find_by_id('type_de_champ_5').find('input[class="order_place"]', visible: false).value).to eq('5');
#         end

#         context 'when to click on down_button type_de_champ_4 and up_button type_de_champ_5' do
#           before do
#             page.click_on 'order_type_de_champ_4_down_procedure'
#             page.click_on 'order_type_de_champ_5_up_procedure'
#           end

#           scenario 'type_de_champ_2 and type_de_champ_3 is reversed' do
#             expect(page.find_by_id('type_de_champ_2').find('input[class="order_place"]', visible: false).value).to eq('1');
#             expect(page.find_by_id('type_de_champ_3').find('input[class="order_place"]', visible: false).value).to eq('2');
#             expect(page.find_by_id('type_de_champ_5').find('input[class="order_place"]', visible: false).value).to eq('3');
#             expect(page.find_by_id('type_de_champ_1').find('input[class="order_place"]', visible: false).value).to eq('4');
#             expect(page.find_by_id('type_de_champ_4').find('input[class="order_place"]', visible: false).value).to eq('5');
#           end

#           context 'when to click on up_button type_de_champ_3 and down_button type_de_champ_1 and up_button type_de_champ_5' do
#             before do
#               page.click_on 'order_type_de_champ_3_up_procedure'
#               page.click_on 'order_type_de_champ_1_down_procedure'
#               page.click_on 'order_type_de_champ_5_up_procedure'
#             end

#             scenario 'type_de_champ_2 and type_de_champ_4 is reversed' do
#               expect(page.find_by_id('type_de_champ_3').find('input[class="order_place"]', visible: false).value).to eq('1');
#               expect(page.find_by_id('type_de_champ_5').find('input[class="order_place"]', visible: false).value).to eq('2');
#               expect(page.find_by_id('type_de_champ_2').find('input[class="order_place"]', visible: false).value).to eq('3');
#               expect(page.find_by_id('type_de_champ_4').find('input[class="order_place"]', visible: false).value).to eq('4');
#               expect(page.find_by_id('type_de_champ_1').find('input[class="order_place"]', visible: false).value).to eq('5');
#             end
#           end
#         end
#       end
#     end
#   end
# end
