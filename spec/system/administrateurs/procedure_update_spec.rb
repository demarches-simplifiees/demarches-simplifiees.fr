require 'system/administrateurs/procedure_spec_helper'

describe 'Administrateurs can edit procedures', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let!(:procedure) do
    create(:procedure_with_dossiers,
      :published,
      :with_path,
      :with_type_de_champ,
      administrateur: administrateur)
  end

  before do
    login_as administrateur.user, scope: :user
  end

  context 'when the procedure is in draft' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :with_path,
        :with_type_de_champ,
        administrateur: administrateur)
    end

    scenario 'the administrator can edit the libelle' do
      visit admin_procedures_path(statut: "brouillons")
      click_on procedure.libelle
      find('#presentation').click

      expect(page).to have_field('procedure_libelle', with: procedure.libelle)

      fill_in('procedure_libelle', with: 'Ma petite démarche')
      click_on 'Enregistrer'

      expect(page).to have_selector('.fr-breadcrumb li', text: 'Ma petite démarche')
    end
  end

  context 'when the procedure is published' do
    scenario 'the administrator can edit the libellé, but can‘t change the path' do
      visit root_path
      click_on procedure.libelle
      find('#presentation').click

      expect(page).to have_field('procedure_libelle', with: procedure.libelle)
      expect(page).not_to have_field('procedure_path')

      fill_in('procedure_libelle', with: 'Ma petite démarche')

      click_on 'Enregistrer'

      expect(page).to have_selector('.fr-breadcrumb li', text: 'Ma petite démarche')
    end
  end

  context 'when we associate tags' do
    scenario 'the administrator can edit and persist the tags' do
      procedure.update!(tags: ['social'])

      visit edit_admin_procedure_path(procedure)
      select_combobox('procedure_tags_combo', 'planete', 'planete', check: false)
      click_on 'Enregistrer'

      expect(procedure.reload.tags).to eq(['social', 'planete'])
    end

    scenario 'the tags are persisted when non interacting with the tags combobox' do
      procedure.update!(tags: ['social'])

      visit edit_admin_procedure_path(procedure)
      click_on 'Enregistrer'

      expect(procedure.reload.tags).to eq(['social'])
    end
  end

  context 'when duree extension > 12' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :published,
        :with_path,
        :with_type_de_champ,
        duree_conservation_dossiers_dans_ds: 24,
        max_duree_conservation_dossiers_dans_ds: 24,
        administrateur: administrateur)
    end

    scenario 'the administrator can edit and persist title' do
      visit edit_admin_procedure_path(procedure)
      fill_in('Titre de la démarche', with: 'Hello')
      expect { click_on 'Enregistrer' }.to change { procedure.reload.libelle }
    end
  end
end
