describe 'As an administrateur I can edit types de champ', js: true do
  let(:administrateur) { procedure.administrateurs.first }
  let(:procedure) { create(:procedure) }

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
    add_champs(count: 3)

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
    add_champ(remove_flash_message: true)

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
    add_champ(remove_flash_message: true)

    fill_in 'Libellé du champ', with: ''
    fill_in 'Description du champ (optionnel)', with: 'description du champ'
    expect(page).not_to have_content('Formulaire enregistré')

    fill_in 'Libellé du champ', with: 'libellé de champ'
    expect(page).to have_content('Formulaire enregistré')
  end

  scenario "adding a repetition champ" do
    add_champ(remove_flash_message: true)

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

    within '.buttons' do
      click_on 'Ajouter un champ'
    end

    within '.type-de-champ:nth-child(2)' do
      select('Bloc répétable', from: 'Type de champ')
      fill_in 'Libellé du champ', with: 'libellé de champ 2'
    end

    expect(page).to have_content('Supprimer', count: 3)
  end

  scenario "adding a carte champ" do
    add_champ(remove_flash_message: true)

    select('Carte', from: 'Type de champ')
    fill_in 'Libellé du champ', with: 'Libellé de champ carte', fill_options: { clear: :backspace }
    check 'Cadastres'

    wait_until { procedure.draft_types_de_champ.first.layer_enabled?(:cadastres) }
    wait_until { procedure.draft_types_de_champ.first.libelle == 'Libellé de champ carte' }
    expect(page).to have_content('Formulaire enregistré')

    preview_window = window_opened_by { click_on 'Prévisualiser le formulaire' }
    within_window(preview_window) do
      expect(page).to have_content('Libellé de champ carte')
      expect(page).to have_content('Ajouter un point sur la carte')
      fill_in 'Ajouter un point sur la carte', with: "48°52'27\"N 002°54'32\"E"
      click_on 'Ajouter le point avec les coordonnées saisies sur la carte'
    end
  end

  scenario "adding a dropdown champ" do
    add_champ(remove_flash_message: true)

    select('Choix unique', from: 'Type de champ')
    fill_in 'Libellé du champ', with: 'Libellé de champ menu déroulant', fill_options: { clear: :backspace }
    fill_in 'Options de la liste', with: 'Un menu', fill_options: { clear: :backspace }
    check "Proposer une option « autre » avec un texte libre"

    wait_until { procedure.draft_types_de_champ.first.drop_down_list_options == ['', 'Un menu'] }
    wait_until { procedure.draft_types_de_champ.first.drop_down_other == "1" }
    expect(page).to have_content('Formulaire enregistré')

    page.refresh

    expect(page).to have_content('Un menu')
  end

  scenario "displaying the estimated fill duration" do
    # It doesn't display anything when there are no champs
    expect(page).not_to have_content('Durée de remplissage estimée')

    # It displays the estimate when adding a new champ
    add_champ
    select('Pièce justificative', from: 'Type de champ')
    expect(page).to have_content('Durée de remplissage estimée : 2 mn')

    # It updates the estimate when updating the champ
    check 'Champ obligatoire'
    expect(page).to have_content('Durée de remplissage estimée : 3 mn')

    # It updates the estimate when removing the champ
    page.accept_alert do
      click_on 'Supprimer'
    end
    expect(page).not_to have_content('Durée de remplissage estimée')
  end
end
