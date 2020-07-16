require 'features/admin/procedure_spec_helper'

feature 'Publication de démarches', js: true do
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

  context 'lorsqu’une démarche est en test' do
    scenario 'un administrateur peut la publier' do
      visit admin_procedures_draft_path
      click_on procedure.libelle
      find('#publish-procedure-link').click
      within "#procedure_show" do
        click_on "Publier"
      end

      within '#publish-modal' do
        expect(find_field('procedure_path').value).to eq procedure.path
        fill_in 'lien_site_web', with: 'http://some.website'
        click_on 'publish'
      end

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('.procedure-lien')
    end
  end

  context 'lorsqu’une démarche est close' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :closed,
        :with_path,
        :with_type_de_champ,
        :with_service,
        instructeurs: instructeurs,
        administrateur: administrateur)
    end

    scenario 'un administrateur peut la publier' do
      visit admin_procedures_archived_path
      click_on procedure.libelle
      find('#publish-procedure-link').click
      within "#procedure_show" do
        click_on "Réactiver"
      end

      within '#publish-modal' do
        expect(find_field('procedure_path').value).to eq procedure.path
        fill_in 'lien_site_web', with: 'http://some.website'
        click_on 'publish'
      end

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('.procedure-lien')
    end
  end

  context 'lorsqu’une démarche est dépublié' do
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :unpublished,
        :with_path,
        :with_type_de_champ,
        :with_service,
        instructeurs: instructeurs,
        administrateur: administrateur)
    end

    scenario 'un administrateur peut la publier' do
      visit admin_procedures_archived_path
      click_on procedure.libelle
      find('#publish-procedure-link').click
      within "#procedure_show" do
        click_on "Réactiver"
      end

      within '#publish-modal' do
        expect(find_field('procedure_path').value).to eq procedure.path
        fill_in 'lien_site_web', with: 'http://some.website'
        click_on 'publish'
      end

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('.procedure-lien')
    end
  end
end
