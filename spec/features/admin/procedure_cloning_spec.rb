require 'features/admin/procedure_spec_helper'

feature 'As an administrateur I wanna clone a procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }

  before do
    create :procedure, :with_service, :with_instructeur,
      aasm_state: :publiee, published_at: Time.zone.now,
      administrateurs: [administrateur],
      libelle: 'libellé de la procédure',
      path: 'libelle-de-la-procedure'
    login_as administrateur.user, scope: :user
  end

  context 'Cloning a procedure owned by the current admin' do
    scenario do
      visit admin_procedures_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      page.all('.clone-btn').first.click
      visit admin_procedures_draft_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      click_on Procedure.last.libelle
      expect(page).to have_current_path(admin_procedure_path(Procedure.last))

      find('#publish-procedure').click

      within '#publish-modal' do
        expect(find_field('procedure_path').value).to eq 'libelle-de-la-procedure'
        expect(page).to have_text('ancienne sera dépubliée')
        fill_in 'lien_site_web', with: 'http://some.website'
        click_on 'publish'
      end

      page.refresh

      visit admin_procedures_archived_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      visit admin_procedures_draft_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('0')
    end
  end
end
