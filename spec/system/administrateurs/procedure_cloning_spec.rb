require 'system/administrateurs/procedure_spec_helper'

describe 'As an administrateur I wanna clone a procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { administrateurs(:default_admin) }
  let(:procedure_path) { 'toto' }

  before do
    create(:procedure, :with_service, :with_instructeur, :with_zone,
      aasm_state: :publiee,
      administrateurs: [administrateur],
      libelle: 'libellé de la procédure',
      path: procedure_path,
      published_at: Time.zone.now)
    login_as administrateur.user, scope: :user
  end
  context 'Visit all admin procedures' do
    let(:download_dir) { Rails.root.join('tmp/capybara') }
    let(:download_file_pattern) { download_dir.join('*.xlsx') }

    scenario do
      Dir[download_file_pattern].map { File.delete(_1) }
      visit all_admin_procedures_path

      click_on "Exporter les résultats"
      Timeout.timeout(Capybara.default_max_wait_time,
                      Timeout::Error,
                     "File download timeout! can't download procedure/all.xlsx") do
        sleep 0.1 until !Dir[download_file_pattern].empty?
      end
    end
  end
  context 'Cloning a procedure owned by the current admin' do
    scenario do
      visit admin_procedures_path
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      page.all('.card .dropdown .fr-btn').first.click
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
      check Zone.last.current_label, allow_label_click: true
      click_on 'Enregistrer'

      # then publish
      find('#publish-procedure-link').click
      # pf default path computed is different
      expect(find_field('procedure_path').value).to eq Procedure.last.service.suggested_path + '-libelle-de-la-procedure'
      fill_in 'procedure_path', with: procedure_path
      expect(page).to have_content 'Si vous publiez cette démarche, l’ancienne sera dépubliée et ne sera plus accessible au public.'

      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'publish'

      page.refresh

      visit admin_procedures_path(statut: "archivees")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      visit admin_procedures_path(statut: "brouillons")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('0')
    end
  end

  context 'Cloning a procedure from the all procedure page' do
    scenario do
      visit all_admin_procedures_path
      expect(page).to have_content(Procedure.last.libelle)
      find('.button_to>button').click
      click_on 'Cloner'
      visit admin_procedures_path(statut: "brouillons")
      expect(page.find_by_id('procedures')['data-item-count']).to eq('1')
      click_on Procedure.last.libelle
      expect(page).to have_current_path(admin_procedure_path(id: Procedure.last))

      # select service
      find("#service .fr-btn").click
      click_on "Assigner"

      # select zone
      find("#zones .fr-btn").click
      check Zone.last.current_label, allow_label_click: true
      click_on 'Enregistrer'

      # then publish
      find('#publish-procedure-link').click
      # pf default path computed is different
      expect(find_field('procedure_path').value).to eq Procedure.last.service.suggested_path + '-libelle-de-la-procedure'
      fill_in 'procedure_path', with: procedure_path
      expect(page).to have_content 'Si vous publiez cette démarche, l’ancienne sera dépubliée et ne sera plus accessible au public.'
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
