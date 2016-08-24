require 'spec_helper'

feature 'add a new type de champs', js: true do

  let(:administrateur) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: administrateur) }

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
      click_button 'Ajouter le champ'
      wait_for_ajax
      procedure.reload
    end
    subject { procedure.types_de_champ.first }
    scenario 'creates the type de champ', js: true do
      expect(page).to have_css('#procedure_types_de_champ_attributes_1_libelle')
      expect(subject.libelle).to eq(libelle)
      expect(subject.type_champ).to eq(type_champ)
      expect(subject.description).to eq(description)
      expect(subject.order_place).to eq(0)
    end

    context 'user fill another one' do
      let(:libelle) { 'coucou' }
      let(:type_champ_value) { 'textarea' }
      let(:type_champ_label) { 'Zone de texte' }
      let(:description) { 'to be or not to be' }
      before do
        page.find_by_id('procedure_types_de_champ_attributes_1_libelle').set libelle
        select(type_champ_label, from: 'procedure_types_de_champ_attributes_1_type_champ')
        page.find_by_id('procedure_types_de_champ_attributes_1_description').set description
        click_button 'Ajouter le champ'
        wait_for_ajax
        procedure.reload
      end
      subject { procedure.types_de_champ.last }
      scenario 'creates another types_de_champ' do
        expect(page).to have_css('#procedure_types_de_champ_attributes_2_libelle')
        expect(subject.libelle).to eq(libelle)
        expect(subject.type_champ).to eq(type_champ_value)
        expect(subject.description).to eq(description)
        expect(subject.order_place).to eq(1)
        expect(procedure.types_de_champ.count).to eq(2)
      end

      context 'user delete the first one' do
        let(:type_de_champ) { procedure.types_de_champ.first }
        before do
          page.find_by_id("delete_type_de_champ_#{type_de_champ.id}").click
          wait_for_ajax
          procedure.reload
        end
        scenario 'deletes type de champ' do
          expect(procedure.types_de_champ.count).to eq(1)
        end
      end
      context 'user modifies the first one' do
        let(:new_libelle) { 'my new field' }
        before do
          page.find_by_id('procedure_types_de_champ_attributes_0_libelle').set(new_libelle)
          page.find_by_id('save').click
          wait_for_ajax
          procedure.reload
        end
        scenario 'saves changes in database' do
          type_de_champ = procedure.types_de_champ.first
          expect(type_de_champ.libelle).to eq(new_libelle)
        end
      end
    end
  end
end
