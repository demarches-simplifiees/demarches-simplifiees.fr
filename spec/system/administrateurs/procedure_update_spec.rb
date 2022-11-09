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
      within('.procedure-form__preview') do
        expect(page).to have_content('Ma petite démarche')
      end

      click_on 'Enregistrer'

      expect(page).to have_selector('.breadcrumbs li', text: 'Ma petite démarche')
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

      expect(page).to have_selector('.breadcrumbs li', text: 'Ma petite démarche')
    end
  end
end
