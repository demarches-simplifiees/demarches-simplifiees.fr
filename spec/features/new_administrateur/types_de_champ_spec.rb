require 'spec_helper'

feature 'As an administrateur I can edit types de champ', js: true do
  let(:administrateur) { procedure.administrateurs.first }
  let(:procedure) { create(:procedure) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:champ_repetition, true)
    login_as administrateur, scope: :administrateur
    visit champs_procedure_path(procedure)
  end

  it "Add a new champ" do
    click_on 'Supprimer'

    within '.buttons' do
      click_on 'Ajouter un champ'
    end
    expect(page).to have_selector('#champ-0-libelle')
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
    within '.buttons' do
      click_on 'Ajouter un champ'
      click_on 'Ajouter un champ'
      click_on 'Ajouter un champ'
    end
    page.refresh

    fill_in 'champ-0-libelle', with: 'libellé de champ 0'
    fill_in 'champ-1-libelle', with: 'libellé de champ 1'
    blur
    expect(page).to have_content('Formulaire enregistré')

    expect(page).to have_selector('#champ-0-libelle')
    expect(page).to have_selector('#champ-1-libelle')
    expect(page).to have_selector('#champ-2-libelle')
    expect(page).to have_selector('#champ-3-libelle')

    within '.type-de-champ[data-index="2"]' do
      click_on 'Supprimer'
    end

    expect(page).not_to have_selector('#champ-3-libelle')
    fill_in 'champ-2-libelle', with: 'libellé de champ 2'
    blur
    expect(page).to have_content('Formulaire enregistré')

    expect(page).to have_content('Supprimer', count: 3)

    page.refresh

    expect(page).to have_content('Supprimer', count: 3)
  end

  it "Remove champs" do
    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')
    page.refresh

    click_on 'Supprimer'
    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 1)
    page.refresh

    expect(page).to have_content('Supprimer', count: 1)
  end

  it "Only add valid champs" do
    expect(page).to have_selector('#champ-0-description')
    fill_in 'champ-0-libelle', with: ''
    fill_in 'champ-0-description', with: 'déscription du champ'
    blur
    expect(page).not_to have_content('Formulaire enregistré')

    fill_in 'champ-0-libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')
  end

  it "Add repetition champ" do
    expect(page).to have_selector('#champ-0-libelle')
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
    select('Carte', from: 'champ-0-type_champ')
    fill_in 'champ-0-libelle', with: 'libellé de champ carte'
    blur
    check 'Quartiers prioritaires'
    expect(page).to have_content('Formulaire enregistré')

    preview_window = window_opened_by { click_on 'Prévisualiser le formulaire' }
    within_window(preview_window) do
      expect(page).to have_content('libellé de champ carte')
      expect(page).to have_content('Quartiers prioritaires')
      expect(page).not_to have_content('Cadastres')
    end
  end
end
