require 'spec_helper'

feature 'add a new type de champs', js: true do

  let(:administrateur) { create(:administrateur) }
  let(:procedure) { create(:procedure) }

  before do
    login_as administrateur, scope: :administrateur
    visit admin_procedure_types_de_champ_path(procedure)
  end

  scenario 'displays a form for type de champs' do
    expect(page).to have_css('#procedure_types_de_champ_attributes_0_libelle')
    expect(page).to have_css('#procedure_types_de_champ_attributes_0_type_champ')
    expect(page).to have_css('#procedure_types_de_champ_attributes_0_description')
    expect(page).to have_css('#add_type_de_champ')
  end

  context 'user fill a new type de champ', js: true do
    let(:libelle) { 'mon libelle' }
    let(:type_champ) { 'text' }
    let(:description) { 'ma super histoire' }
    before do
      page.find_by_id('procedure_types_de_champ_attributes_0_libelle').set libelle
      page.find_by_id('procedure_types_de_champ_attributes_0_type_champ').set type_champ
      page.find_by_id('procedure_types_de_champ_attributes_0_description').set description
      click_button 'Ajouter un champ'
      procedure.reload
    end
    subject { procedure.types_de_champ.first }
    scenario 'creates the type de champ', js: true do
      expect(page).to have_css('#procedure_types_de_champ_attributes_1_libelle')
      expect(subject.libelle).to eq(libelle)
      expect(subject.type_champ).to eq(type_champ)
      expect(subject.description).to eq(description)
    end
  end

end
#   context 'when create a new procedure' do
#     before do
#       visit new_admin_procedure_path
#     end

#     scenario 'page have form to created new type de champs' do
#       expect(page).to have_css('#type_de_champ_0')
#       expect(page).to have_css('input[name="procedure[new_type_de_champ[0]][libelle]"]')
#       expect(page).to have_css('select[name="procedure[new_type_de_champ[0]][type_champ]"]')
#       expect(page).to have_css('textarea[name="procedure[new_type_de_champ[0]][description]"]')
#       expect(page).to have_css('input[name="procedure[new_type_de_champ[0]][order_place]"]', visible: false)
#       expect(page).to have_css('input[name="procedure[new_type_de_champ[0]][_destroy]"]', visible: false)

#       expect(page).to have_css('#order_type_de_champ_0_button', visible: false);
#       expect(page).to have_css('#order_type_de_champ_0_up_procedure', visible: false);
#       expect(page).to have_css('#order_type_de_champ_0_down_procedure', visible: false);

#       expect(page).to have_css('#new_type_de_champ #add_type_de_champ_button')
#     end

#     context 'when user add a new champs type' do
#       before do
#         page.find_by_id('procedure_new_type_de_champ_0__libelle').set 'Libelle de test'
#         page.find_by_id('procedure_new_type_de_champ_0__description').set 'Description de test'
#         page.click_on 'add_type_de_champ_procedure'
#       end

#       scenario 'a new champs type line is appeared with increment index id' do
#         expect(page).to have_css('#type_de_champ_1')
#         expect(page).to have_css('input[name="procedure[new_type_de_champ[1]][libelle]"]')
#         expect(page).to have_css('select[name="procedure[new_type_de_champ[1]][type_champ]"]')
#         expect(page).to have_css('textarea[name="procedure[new_type_de_champ[1]][description]"]')
#         expect(page).to have_css('input[name="procedure[new_type_de_champ[1]][order_place]"]', visible: false)
#         expect(page).to have_css('input[name="procedure[new_type_de_champ[1]][_destroy]"]', visible: false)

#         expect(page).to have_css('#order_type_de_champ_1_button', visible: false);
#         expect(page).to have_css('#order_type_de_champ_1_up_procedure', visible: false);
#         expect(page).to have_css('#order_type_de_champ_1_down_procedure', visible: false);
#       end

#       scenario 'the first line is filled' do
#         expect(page.find_by_id('procedure_new_type_de_champ_0__libelle').value).to eq('Libelle de test')
#         expect(page.find_by_id('procedure_new_type_de_champ_0__description').value).to eq('Description de test')
#         expect(page.find_by_id('procedure_new_type_de_champ_0__order_place', visible: false).value).to eq('1')
#       end

#       scenario 'the first line have new button delete' do
#         expect(page).to have_css('#delete_type_de_champ_0_button')
#         expect(page).to have_css('#delete_type_de_champ_0_procedure')
#       end

#       scenario 'the new line is empty' do
#         expect(page.find_by_id('procedure_new_type_de_champ_1__libelle').value).to eq('')
#         expect(page.find_by_id('procedure_new_type_de_champ_1__description').value).to eq('')
#         expect(page.find_by_id('procedure_new_type_de_champ_1__order_place', visible: false).value).to eq('2')
#         expect(page.find_by_id('procedure_new_type_de_champ_1___destroy', visible: false).value).to eq('false')
#       end

#       scenario 'the button Ajouter is at side new line' do
#         expect(page).to have_css('#new_type_de_champ #type_de_champ_1 #add_type_de_champ_button')
#         expect(page).not_to have_css('#type_de_champ_0 #add_type_de_champ_button')
#       end
#     end
#   end
# end
