require 'system/administrateurs/procedure_spec_helper'

describe 'Publishing a procedure', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let(:instructeurs) { [administrateur.user.instructeur] }
  let!(:procedure) do
    create(:procedure_with_dossiers,
      :with_path,
      :with_type_de_champ,
      :with_service,
      instructeurs: instructeurs,
      administrateur: administrateur)
  end

  before do
    login_as administrateur.user, scope: :user
  end

  context 'when using a deprecated back-office URL' do
    scenario 'the admin is redirected to the draft procedure' do
      visit admin_procedures_draft_path
      expect(page).to have_current_path(admin_procedures_path(statut: "brouillons"))
    end

    scenario 'the admin is redirected to the archived procedures' do
      visit admin_procedures_archived_path
      expect(page).to have_current_path(admin_procedures_path(statut: "archivees"))
    end
  end

  context 'when a procedure isn’t published yet' do
    scenario 'an admin can publish it' do
      visit admin_procedures_path(statut: "brouillons")
      click_on procedure.libelle
      find('#publish-procedure-link').click
      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'Publier'

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('#preview-procedure')
    end
  end

  context 'when a procedure is closed' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :closed,
        :with_path,
        :with_type_de_champ,
        :with_service,
        instructeurs: instructeurs,
        administrateur: administrateur)
    end

    scenario 'an admin can publish it again' do
      visit admin_procedures_path(statut: "archivees")
      click_on procedure.libelle
      find('#publish-procedure-link').click

      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'publish'

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('#preview-procedure')
    end
  end

  context 'when a procedure is de-published' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :unpublished,
        :with_path,
        :with_type_de_champ,
        :with_service,
        instructeurs: instructeurs,
        administrateur: administrateur)
    end

    scenario 'an admin can publish it again' do
      visit admin_procedures_path(statut: "archivees")
      click_on procedure.libelle
      find('#publish-procedure-link').click

      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'Publier'

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('#preview-procedure')
    end
  end
end
