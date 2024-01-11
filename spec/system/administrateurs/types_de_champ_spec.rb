describe 'As an administrateur I can edit types de champ', js: true do
  include ActionView::RecordIdentifier

  let(:administrateur) { procedure.administrateurs.first }
  let(:estimated_duration_visible) { true }
  let(:procedure) { create(:procedure, estimated_duration_visible:) }

  before do
    login_as administrateur.user, scope: :user
    visit champs_admin_procedure_path(procedure)
  end

  scenario "adding a new champ" do
    add_champ

    fill_in 'Libellé du champ', with: 'libellé de champ'
    expect(page).to have_content('Formulaire enregistré')
  end

  scenario "adding a piece justificative template" do
    add_champ
    select('Pièce justificative', from: 'Type de champ')

    find('.attachment input[type=file]').attach_file(Rails.root + 'spec/fixtures/files/file.pdf')

    # Expect the files to be uploaded immediately
    expect(page).to have_text('file.pdf')
  end

  scenario "adding multiple champs" do
    # Champs are created when clicking the 'Add field' button
    add_champ
    within(find('.type-de-champ-add-button', match: :first)) {
      add_champ
    }
    within(find('.type-de-champ-add-button', match: :first)) {
      add_champ
    }

    # Champs are automatically saved
    expect(page).to have_button('Ajouter un champ', disabled: false)
    page.refresh
    expect(page).to have_selector('.type-de-champ', count: 3)

    # Multiple champs can be edited
    within '.type-de-champ:nth-child(1)' do
      fill_in 'Libellé du champ', with: 'libellé de champ 0'
    end
    within '.type-de-champ:nth-child(2)' do
      fill_in 'Libellé du champ', with: 'libellé de champ 1'
    end
    expect(page).to have_content('Formulaire enregistré')

    # Champs can be deleted
    within '.type-de-champ:nth-child(3)' do
      page.accept_alert do
        click_on 'Supprimer'
      end
    end
    expect(page).to have_content('Supprimer', count: 2)

    within '.type-de-champ:nth-child(2)' do
      fill_in 'Libellé du champ', with: 'edited libellé de champ 1'
    end
    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 2)

    page.refresh
    expect(page).to have_content('Supprimer', count: 2)
  end

  scenario "removing champs" do
    add_champ
    hide_autonotice_message

    fill_in 'Libellé du champ', with: 'libellé de champ'
    expect(page).to have_content('Formulaire enregistré')

    page.refresh

    page.accept_alert do
      click_on 'Supprimer'
    end
    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 0)
    page.refresh

    expect(page).to have_content('Supprimer', count: 0)
  end

  scenario "adding an invalid champ" do
    add_champ
    hide_autonotice_message

    fill_in 'Libellé du champ', with: ''
    fill_in 'Description du champ (optionnel)', with: 'description du champ'
    expect(page).to have_no_text(:visible, 'Formulaire enregistré')

    fill_in 'Libellé du champ', with: 'libellé de champ'
    expect(page).to have_text('Formulaire enregistré')
  end

  scenario "adding a repetition champ" do
    add_champ
    hide_autonotice_message

    select('Bloc répétable', from: 'Type de champ')
    fill_in 'Libellé du champ', with: 'libellé de champ'

    expect(page).to have_content('Formulaire enregistré')
    page.refresh

    within '.type-de-champ .editor-block' do
      click_on 'Ajouter un champ'

      fill_in 'Libellé du champ', with: 'libellé de champ 1'
    end

    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 2)

    page.all('.fr-icon-add-line')[2].click

    within '.type-de-champ:nth-child(2)' do
      select('Bloc répétable', from: 'Type de champ')
      fill_in 'Libellé du champ', with: 'libellé de champ 2'
    end

    expect(page).to have_content('Supprimer', count: 3)
  end

  scenario "adding a carte champ" do
    add_champ
    hide_autonotice_message

    select('Carte', from: 'Type de champ')
    fill_in 'Libellé du champ', with: 'Libellé de champ carte', fill_options: { clear: :backspace }
    check 'Cadastres'

    wait_until { procedure.active_revision.types_de_champ_public.first.layer_enabled?(:cadastres) }
    wait_until { procedure.active_revision.types_de_champ_public.first.libelle == 'Libellé de champ carte' }
    expect(page).to have_content('Formulaire enregistré')

    page.refresh
    preview_window = window_opened_by { click_on 'Prévisualiser le formulaire' }
    within_window(preview_window) do
      expect(page).to have_content('Libellé de champ carte')
      expect(page).to have_content('Ajouter un point sur la carte')
      fill_in 'Ajouter un point sur la carte', with: "48°52'27\"N 002°54'32\"E"
      click_on 'Ajouter le point avec les coordonnées saisies sur la carte'
    end
  end

  scenario "adding a dropdown champ" do
    add_champ
    hide_autonotice_message

    select('Choix simple', from: 'Type de champ')
    fill_in 'Libellé du champ', with: 'Libellé de champ menu déroulant', fill_options: { clear: :backspace }
    fill_in 'Options de la liste', with: 'Un menu', fill_options: { clear: :backspace }
    check "Proposer une option « autre » avec un texte libre"

    wait_until { procedure.active_revision.types_de_champ_public.first.drop_down_list_options == ['', 'Un menu'] }
    wait_until { procedure.active_revision.types_de_champ_public.first.drop_down_other == "1" }
    expect(page).to have_content('Formulaire enregistré')

    page.refresh

    expect(page).to have_content('Un menu')
  end

  context "estimated duration visible" do
    scenario "displaying the estimated fill duration" do
      # It doesn't display anything when there are no champs
      expect(page).not_to have_content('Durée de remplissage estimée')

      # It displays the estimate when adding a new champ
      add_champ
      select('Pièce justificative', from: 'Type de champ')
      expect(page).to have_content('Durée de remplissage estimée : 2 min')

      # It updates the estimate when updating the champ
      check 'Champ obligatoire'
      expect(page).to have_content('Durée de remplissage estimée : 3 min')

      # It updates the estimate when removing the champ
      page.accept_alert do
        click_on 'Supprimer'
      end
      expect(page).not_to have_content('Durée de remplissage estimée')
    end
  end

  context "estimated duration not visible" do
    let(:estimated_duration_visible) { false }

    scenario "hide the estimated fill duration" do
      # It doesn't display anything when there are no champs
      expect(page).not_to have_content('Durée de remplissage estimée')

      # It displays the estimate when adding a new champ
      add_champ
      select('Pièce justificative', from: 'Type de champ')
      expect(page).not_to have_content('Durée de remplissage estimée')
    end
  end

  context 'header section' do
    scenario 'invalid order, it pops up errors summary' do
      add_champ
      select('Titre de section', from: 'Type de champ')
      wait_until { procedure.reload.active_revision.types_de_champ_public.first&.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      first_header = procedure.active_revision.types_de_champ_public.first
      select('Titre de niveau 1', from: dom_id(first_header, :header_section_level))

      within(find('.type-de-champ-add-button', match: :first)) {
        add_champ
      }

      wait_until { procedure.reload.active_revision.types_de_champ_public.count == 2 }
      second_header = procedure.active_revision.types_de_champ_public.last
      select('Titre de section', from: dom_id(second_header, :type_champ))
      wait_until { procedure.reload.active_revision.types_de_champ_public.last&.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      select('Titre de niveau 2', from: dom_id(second_header, :header_section_level))

      within(".types-de-champ-block li:first-child") do
        page.accept_alert do
          click_on 'Supprimer'
        end
      end

      expect(page).to have_content("Le formulaire contient des erreurs")
      expect(page).to have_content("Le titre de section suivant est invalide, veuillez le corriger :")
    end
  end

  context 'move and morph champs' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text, libelle: 'first_tdc' }, { type: :text, libelle: 'middle_tdc' }, { type: :text, libelle: 'last_tdc' }]) }
    let!(:initial_first_coordinate) { procedure.draft_revision.revision_types_de_champ[0] }
    let!(:initial_second_coordinate) { procedure.draft_revision.revision_types_de_champ[1] }
    let!(:initial_third_coordinate) { procedure.draft_revision.revision_types_de_champ[2] }
    # TODO: check no select when 1 champs
    # TODO: check empty select when 1 champs
    # TODO: check select is seeding on focus
    # TODO: check select.change move champ and keep order
    # TODO: select options are segmented by block
    scenario 'root champs' do
      initial_order = [initial_first_coordinate, initial_second_coordinate, initial_third_coordinate].map(&:stable_id)
      initial_first_coordinate_selector = "##{ActionView::RecordIdentifier.dom_id(initial_first_coordinate, :move_and_morph)}"
      # at first, select only contains the current coordinate
      expect(page).to have_selector("#{initial_first_coordinate_selector} option", count: 1)
      expect(page.find(initial_first_coordinate_selector).all("option").first.value.to_s).to eq(initial_first_coordinate.stable_id.to_s)

      # once clicked, the select is updated other options
      page.find(initial_first_coordinate_selector).click
      expect(page).to have_selector("#{initial_first_coordinate_selector} option", count: 4)
      #   also we re-hydrate the selected value
      expect(page.find(initial_first_coordinate_selector).find("option[selected]").value.to_s).to eq(initial_first_coordinate.stable_id.to_s)
      page.find(initial_first_coordinate_selector).select(initial_third_coordinate.libelle)
      wait_until do
        procedure.reload.draft_revision.revision_types_de_champ.last.type_de_champ.libelle == initial_first_coordinate.type_de_champ.libelle
      end
      expect(procedure.reload.draft_revision.revision_types_de_champ.map(&:stable_id))
        .to eq([initial_second_coordinate, initial_third_coordinate, initial_first_coordinate].map(&:stable_id))
    end

    scenario 'repetition champs' do
    end
  end
end
