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
    before do
      visit admin_procedures_path(statut: "brouillons")
      click_on procedure.libelle
      find('#publish-procedure-link').click
    end

    scenario 'an admin can publish it' do
      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'Publier'

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('#preview-procedure')
    end

    context 'when the procedure has invalid champs' do
      let(:empty_repetition) { build(:type_de_champ_repetition, types_de_champ: [], libelle: 'Enfants') }
      let(:empty_drop_down) { build(:type_de_champ_drop_down_list, :without_selectable_values, libelle: 'Civilité') }

      let!(:procedure) do
        create(:procedure,
               :with_path,
               :with_service,
               instructeurs: instructeurs,
               administrateur: administrateur,
               types_de_champ: [empty_repetition],
               types_de_champ_private: [empty_drop_down])
      end

      scenario 'an error message prevents the publication' do
        expect(page).to have_content('Des problèmes empêchent la publication de la démarche')
        expect(page).to have_content("Le champ « Enfants » doit comporter au moins un champ répétable")
        expect(page).to have_content("L’annotation privée « Civilité » doit comporter au moins un choix sélectionnable")

        expect(find_field('procedure_path').value).to eq procedure.path
        fill_in 'lien_site_web', with: 'http://some.website'

        expect(page).to have_button('Publier', disabled: true)
      end
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
