require 'spec_helper'

feature 'As an administrateur I can edit types de champ', js: true do
  let(:administrateur) { procedure.administrateur }
  let(:procedure) { create(:procedure) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:champ_repetition, true)
    login_as administrateur, scope: :administrateur
    visit champs_procedure_path(procedure)
  end

  it "Add a new champ" do
    click_on 'Supprimer'

    within '.footer' do
      click_on 'Ajouter un champ'
    end
    expect(page).to have_selector('#procedure_types_de_champ_attributes_0_libelle')
    fill_in 'procedure_types_de_champ_attributes_0_libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')

    page.refresh
    within '.footer' do
      click_on 'Enregistrer'
    end

    expect(page).to have_content('Formulaire enregistré')
  end

  it "Add multiple champs" do
    within '.footer' do
      click_on 'Ajouter un champ'
      click_on 'Ajouter un champ'
      click_on 'Ajouter un champ'
    end
    expect(page).not_to have_content('Formulaire enregistré')

    fill_in 'procedure_types_de_champ_attributes_0_libelle', with: 'libellé de champ 0'
    fill_in 'procedure_types_de_champ_attributes_1_libelle', with: 'libellé de champ 1'
    blur
    expect(page).to have_content('Formulaire enregistré')

    expect(page).to have_selector('#procedure_types_de_champ_attributes_0_libelle')
    expect(page).to have_selector('#procedure_types_de_champ_attributes_1_libelle')
    expect(page).to have_selector('#procedure_types_de_champ_attributes_2_libelle')
    expect(page).to have_selector('#procedure_types_de_champ_attributes_3_libelle')

    within '.draggable-item-2' do
      click_on 'Supprimer'
    end

    expect(page).not_to have_selector('#procedure_types_de_champ_attributes_3_libelle')
    fill_in 'procedure_types_de_champ_attributes_2_libelle', with: 'libellé de champ 2'
    blur
    expect(page).to have_content('Formulaire enregistré')

    expect(page).to have_content('Supprimer', count: 3)

    page.refresh

    expect(page).to have_content('Supprimer', count: 3)
  end

  it "Remove champs" do
    fill_in 'procedure_types_de_champ_attributes_0_libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')
    page.refresh

    click_on 'Supprimer'
    expect(page).to have_content('Formulaire enregistré')
    expect(page).not_to have_content('Supprimer')
    page.refresh

    expect(page).to have_content('Supprimer', count: 1)
  end

  it "Only add valid champs" do
    expect(page).to have_selector('#procedure_types_de_champ_attributes_0_description')
    fill_in 'procedure_types_de_champ_attributes_0_description', with: 'déscription du champ'
    blur
    expect(page).not_to have_content('Formulaire enregistré')

    fill_in 'procedure_types_de_champ_attributes_0_libelle', with: 'libellé de champ'
    blur
    expect(page).to have_content('Formulaire enregistré')
  end

  it "Add repetition champ" do
    expect(page).to have_selector('#procedure_types_de_champ_attributes_0_libelle')
    select('Bloc répétable', from: 'procedure_types_de_champ_attributes_0_type_champ')
    fill_in 'procedure_types_de_champ_attributes_0_libelle', with: 'libellé de champ'
    blur

    expect(page).to have_content('Formulaire enregistré')
    page.refresh

    within '.flex-grow' do
      click_on 'Ajouter un champ'
    end

    fill_in 'procedure_types_de_champ_attributes_0_types_de_champ_attributes_0_libelle', with: 'libellé de champ 1'
    blur

    expect(page).to have_content('Formulaire enregistré')
    expect(page).to have_content('Supprimer', count: 2)

    within '.footer' do
      click_on 'Ajouter un champ'
    end

    select('Bloc répétable', from: 'procedure_types_de_champ_attributes_1_type_champ')
    fill_in 'procedure_types_de_champ_attributes_1_libelle', with: 'libellé de champ 2'
    blur

    expect(page).to have_content('Supprimer', count: 3)
  end
end
