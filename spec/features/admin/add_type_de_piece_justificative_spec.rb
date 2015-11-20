require 'spec_helper'

feature 'add a new type de piece justificative', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end
  context 'when there is no piece justificative' do
    let(:procedure) { create(:procedure, administrateur: administrateur) }
    before do
      visit admin_procedure_pieces_justificatives_path(procedure)
    end
    scenario 'displays a form to add new type de piece justificative' do
      expect(page).to have_css('#procedure_types_de_piece_justificative_attributes_0_libelle')
    end
    context 'when user fills field and submit' do
      let(:libelle) { 'ma piece' }
      let(:description) { 'ma description' }
      before do
        page.find_by_id('procedure_types_de_piece_justificative_attributes_0_libelle').set(libelle)
        page.find_by_id('procedure_types_de_piece_justificative_attributes_0_description').set(description)
        page.click_on 'Ajouter la pièce'
        wait_for_ajax
      end
      subject do
        procedure.reload
        procedure.types_de_piece_justificative.first
      end
      scenario 'creates new type de piece' do
        expect(subject.libelle).to eq(libelle)
        expect(subject.description).to eq(description)
      end
    end
  end
end
