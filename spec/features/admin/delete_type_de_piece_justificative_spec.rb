require 'spec_helper'

# feature 'delete a type de piece_justificative form', js: true do
#   let(:administrateur) { create(:administrateur) }

#   before do
#     login_as administrateur, scope: :administrateur
#   end

#   context 'when user click on type de piece_justificative red X button' do
#     let!(:procedure) { create(:procedure, :with_two_type_de_piece_justificative) }

#     before do
#       visit admin_procedure_path id: procedure.id
#     end

#     context 'when user edit a type de piece_justificative already save in database' do
#       let(:type_de_piece_justificative) { procedure.types_de_piece_justificative.first }

#       before do
#         page.click_on 'delete_type_de_piece_justificative_1_procedure'
#       end

#       scenario 'form is mask for the user' do
#         expect(page.find_by_id('type_de_piece_justificative_1', visible: false).visible?).to be_falsey
#       end

#       scenario 'delete attribut of type de piece_justificative is turn to true' do
#         expect(page.find_by_id('type_de_piece_justificative_1', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
#       end
#     end

#     context 'when user edit a type de piece_justificative just add on the form page' do
#       before do
#         page.click_on 'add_type_de_piece_justificative_procedure'
#         page.click_on 'add_type_de_piece_justificative_procedure'
#         page.click_on 'delete_type_de_piece_justificative_2_procedure'
#         page.click_on 'delete_type_de_piece_justificative_3_procedure'
#       end

#       scenario 'form is mask for the user' do
#         expect(page.find_by_id('type_de_piece_justificative_2', visible: false).visible?).to be_falsey
#         expect(page.find_by_id('type_de_piece_justificative_3', visible: false).visible?).to be_falsey
#       end

#       scenario 'delete attribut of type de piece_justificative is turn to true' do
#         expect(page.find_by_id('type_de_piece_justificative_2', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
#         expect(page.find_by_id('type_de_piece_justificative_3', visible: false).find('input[class="destroy"]', visible: false).value).to eq('true')
#       end
#     end
#   end
# end
