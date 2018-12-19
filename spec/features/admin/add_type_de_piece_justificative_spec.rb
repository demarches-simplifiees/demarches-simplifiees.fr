require 'spec_helper'

feature 'add a new type de piece justificative', js: true do
  let(:administrateur) { create(:administrateur) }

  before do
    login_as administrateur, scope: :administrateur
  end
  context 'when there is an existing piece justificative' do
    let(:procedure) { create(:procedure, administrateur: administrateur) }
    before do
      # Create a dummy PJ, because adding PJs is no longer allowed on procedures that
      # do not already have one
      procedure.types_de_piece_justificative.create(libelle: "dummy PJ")
      visit admin_procedure_pieces_justificatives_path(procedure)
    end
    scenario 'displays a form to add new type de piece justificative' do
      within '#new_type_de_piece_justificative' do
        expect(page).to have_css('#procedure_types_de_piece_justificative_attributes_1_libelle')
      end
    end
    context 'when user fills field and submit' do
      let(:libelle) { 'ma piece' }
      let(:description) { 'ma description' }
      before do
        page.find_by_id('procedure_types_de_piece_justificative_attributes_1_libelle').set(libelle)
        page.find_by_id('procedure_types_de_piece_justificative_attributes_1_description').set(description)
        page.click_on 'Ajouter la pièce'
        wait_for_ajax
      end
      subject do
        procedure.reload
        procedure.types_de_piece_justificative.second
      end
      scenario 'creates new type de piece' do
        expect(subject.libelle).to eq(libelle)
        expect(subject.description).to eq(description)
      end
      scenario 'displays new created pj' do
        within '#liste_piece_justificative' do
          expect(page).to have_css('#procedure_types_de_piece_justificative_attributes_1_libelle')
          expect(page.body).to match(libelle)
          expect(page.body).to match(description)
        end
        within '#new_type_de_piece_justificative' do
          expect(page).to have_css('#procedure_types_de_piece_justificative_attributes_2_libelle')
        end
      end
      context 'when user delete pj' do
        before do
          pj = procedure.types_de_piece_justificative.second
          page.find_by_id("delete_type_de_piece_justificative_#{pj.id}").click
          wait_for_ajax
        end
        scenario 'removes pj from page' do
          within '#liste_piece_justificative' do
            expect(page).not_to have_css('#procedure_types_de_piece_justificative_attributes_1_libelle')
            expect(page.body).not_to match(libelle)
            expect(page.body).not_to match(description)
          end
        end
      end
      context 'when user change existing type de pj' do
        let(:new_libelle) { 'mon nouveau libelle' }
        before do
          page.find_by_id('procedure_types_de_piece_justificative_attributes_1_libelle').set(new_libelle)
          page.find_by_id('save').click
          wait_for_ajax
        end
        scenario 'saves change in database' do
          pj = procedure.types_de_piece_justificative.second
          expect(pj.libelle).to eq(new_libelle)
        end
      end
    end
  end
end
