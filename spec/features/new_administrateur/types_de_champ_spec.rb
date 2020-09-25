feature 'As an administrateur I can edit types de champ', js: true do
  let(:administrateur) { procedure.administrateurs.first }
  let(:procedure) { create(:procedure) }

  before do
    login_as administrateur.user, scope: :user
    visit champs_admin_procedure_path(procedure)
  end

  it "Add a new champ" do
    add_champ

    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')

    page.refresh
    within '.buttons' do
      click_on 'Enregistrer'
    end
    expect(page).to have_content('Formulaire enregistré')
  end

  it "Add multiple champs" do
    # Champs are created when clicking the 'Add field' button
    add_champs(count: 3)

    # Champs are automatically saved
    expect(page).to have_button('Ajouter un champ', disabled: false)
    page.refresh
    expect(page).to have_selector('.type-de-champ', count: 3)

    # Multiple champs can be edited
    fill_in 'champ-0-libelle', with: 'libellé de champ 0'
    fill_in 'champ-1-libelle', with: 'libellé de champ 1'
    blur
    expect(page).to have_content('Formulaire enregistré')

    # Champs can be deleted
    within '.type-de-champ[data-index="2"]' do
      page.accept_alert do
        click_on 'Supprimer'
      end
    end
    expect(page).not_to have_selector('#champ-2-libelle')

    fill_in 'champ-1-libelle', with: 'edited libellé de champ 1'
    blur
    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 2)

    page.refresh
    expect(page).to have_content('Supprimer', count: 2)
  end

  it "Remove champs" do
    add_champ(remove_flash_message: true)

    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur
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

  it "Only add valid champs" do
    add_champ(remove_flash_message: true)

    fill_in 'champ-0-libelle', with: ''
    fill_in 'champ-0-description', with: 'description du champ'
    blur
    expect(page).not_to have_content('Formulaire enregistré')

    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')
  end

  it "Add repetition champ" do
    add_champ(remove_flash_message: true)

    select('Bloc répétable', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur

    expect(page).to have_content('Formulaire enregistré')
    page.refresh

    within '.type-de-champ .repetition' do
      click_on 'Ajouter un champ'
    end

    fill_in 'repetition-0-champ-0-libelle', with: 'libellé de champ 1'
    blur

    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 2)

    within '.buttons' do
      click_on 'Ajouter un champ'
    end

    select('Bloc répétable', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'libellé de champ 2'
    blur

    expect(page).to have_content('Supprimer', count: 3)
  end

  it "Add carte champ" do
    add_champ

    select('Carte de France', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'Libellé de champ carte', fill_options: { clear: :backspace }
    check 'Cadastres'

    wait_until { procedure.draft_types_de_champ.first.cadastres == true }
    expect(page).to have_content('Formulaire enregistré')

    preview_window = window_opened_by { click_on 'Prévisualiser le formulaire' }
    within_window(preview_window) do
      expect(page).to have_content('Libellé de champ carte')
      expect(page).to have_content('Parcelles cadastrales')
    end
  end

  it "Add te_fenua champ" do
    add_champ

    select('Carte de Polynésie', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'Libellé de champ Te Fenua', fill_options: { clear: :backspace }
    check 'Batiments'
    check 'Parcelles du cadastre'
    check 'Zones manuelles'

    wait_until { procedure.types_de_champ.first.batiments == true }
    expect(page).to have_content('Formulaire enregistré')

    preview_window = window_opened_by { click_on 'Prévisualiser le formulaire' }
    within_window(preview_window) do
      expect(page).to have_content('Libellé de champ Te Fenua')
    end
  end

  it "Add dropdown champ" do
    add_champ

    select('Choix parmi une liste', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'Libellé de champ menu déroulant', fill_options: { clear: :backspace }
    fill_in 'champ-0-drop_down_list_value', with: 'Un menu', fill_options: { clear: :backspace }

    wait_until { procedure.draft_types_de_champ.first.drop_down_list_options == ['', 'Un menu'] }
    expect(page).to have_content('Formulaire enregistré')

    page.refresh

    expect(page).to have_content('Un menu')
  end
end
