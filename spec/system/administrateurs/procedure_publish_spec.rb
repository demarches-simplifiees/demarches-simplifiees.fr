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
      :with_zone,
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
      let!(:procedure) do
        create(:procedure,
               :with_path,
               :with_service,
               :with_zone,
               instructeurs: instructeurs,
               administrateur: administrateur,
               types_de_champ_public: [{ type: :repetition, libelle: 'Enfants', children: [] }, { type: :drop_down_list, libelle: 'Civilité', options: [] }],
               types_de_champ_private: [{ type: :drop_down_list, libelle: 'Civilité', options: [] }])
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

  context 'when a procedure is closed with revision changes' do
    let!(:tdc) { { type_champ: :text, libelle: 'nouveau champ' } }
    let!(:procedure) do
      create(:procedure_with_dossiers,
        :closed,
        :with_path,
        :with_type_de_champ,
        :with_service,
        instructeurs: instructeurs,
        administrateur: administrateur)
    end

    before do
      Flipper.enable(:procedure_revisions, procedure)
      procedure.draft_revision.add_type_de_champ(tdc)
    end

    scenario 'an admin can publish it again' do
      visit admin_procedures_path(statut: "archivees")
      click_on procedure.libelle
      find('#publish-procedure-link').click

      expect(page).to have_text('Les modifications suivantes seront appliquées')
      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      find('#publish').click

      expect(page).to have_text('Démarche publiée')
      expect(page).to have_selector('#preview-procedure')
    end
  end

  context 'when a procedure has dubious champs' do
    let(:dubious_champs) do
      [
        { libelle: 'NIR' },
        { libelle: 'carte bancaire' }
      ]
    end
    let(:not_dubious_champs) do
      [{ libelle: 'Prénom' }]
    end
    let!(:procedure) do
      create(:procedure,
               :with_service,
               instructeurs: instructeurs,
               administrateur: administrateur,
               types_de_champ_public: not_dubious_champs + dubious_champs)
    end

    scenario 'an admin can publish it, but a warning appears' do
      visit admin_procedures_path(statut: "brouillons")
      click_on procedure.libelle
      find('#publish-procedure-link').click

      expect(page).to have_content("Attention, certains champs ne peuvent être demandé par l'administration.")
      expect(page).to have_selector(".dubious-champs", count: dubious_champs.size)
    end
  end
end
