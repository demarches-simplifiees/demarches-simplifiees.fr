require 'system/administrateurs/procedure_spec_helper'

describe 'As an administrateur I wanna clone a procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }

  before do
    create(:procedure, :with_service, :with_instructeur, :with_zone,
      aasm_state: :publiee,
      administrateurs: [administrateur],
      libelle: 'libellé de la procédure',
      path: 'libelle-de-la-procedure')
    login_as administrateur.user, scope: :user
  end

  context 'Cloning a procedure owned by the current admin' do
    scenario do
      visit admin_procedures_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      page.all('.admin-procedures-list-row .dropdown .fr-btn').first.click
      page.all('.clone-btn').first.click
      visit admin_procedures_path(statut: "brouillons")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      click_on Procedure.last.libelle
      expect(page).to have_current_path(admin_procedure_path(id: Procedure.last))

      # select service
      find("#service .fr-btn").click
      click_on "Assigner"

      # select zone
      find("#zones .fr-btn").click
      check Zone.last.current_label
      click_on 'Enregistrer'

      # then publish
      find('#publish-procedure-link').click
      expect(find_field('procedure_path').value).to eq 'libelle-de-la-procedure'
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'publish'

      page.refresh

      visit admin_procedures_path(statut: "archivees")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      visit admin_procedures_path(statut: "brouillons")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('0')
    end
  end
end
