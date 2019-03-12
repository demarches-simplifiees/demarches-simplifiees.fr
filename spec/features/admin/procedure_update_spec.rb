require 'spec_helper'
require 'features/admin/procedure_spec_helper'

feature 'Administrateurs can edit procedures', js: true do
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
    login_as administrateur, scope: :administrateur
  end

  context 'when the procedure is in draft' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :with_path,
        :with_type_de_champ,
        administrateur: administrateur)
    end

    scenario 'the administrator can edit the libelle' do
      visit admin_procedures_draft_path
      click_on procedure.libelle
      click_on 'Description'

      expect(page).to have_field('procedure_libelle', with: procedure.libelle)

      fill_in('procedure_libelle', with: 'Ma petite démarche')

      click_on 'Enregistrer'

      expect(page).to have_field('procedure_libelle', with: 'Ma petite démarche')
    end
  end

  context 'when the procedure is published' do
    scenario 'the administrator can edit the libellé, but can‘t change the path' do
      visit root_path
      click_on procedure.libelle
      click_on 'Description'

      expect(page).to have_field('procedure_libelle', with: procedure.libelle)
      expect(page).not_to have_field('procedure_path')

      fill_in('procedure_libelle', with: 'Ma petite démarche')

      click_on 'Enregistrer'

      expect(page).to have_field('procedure_libelle', with: 'Ma petite démarche')
    end
  end
end
