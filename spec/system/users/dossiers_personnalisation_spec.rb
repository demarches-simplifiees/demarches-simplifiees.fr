# frozen_string_literal: true

describe 'Usager personnalise la liste des dossiers', js: true do
  let(:user) { create(:user) }
  let(:procedure) do
    create(:procedure, :published, public_type_de_champs: [
      { type: :header_section, libelle: 'Identité' },
      { type: :text, libelle: 'Nom du titre', mandatory: true },
      { type: :text, libelle: 'Numéro CPPAP' },
    ])
  end

  before do
    create_list(:dossier, 6, :en_construction, user:, procedure:)
    login_as user, scope: :user
  end

  it 'shows the chosen champ values on the dossier cards' do
    perso_procedure = create(:procedure, :published, public_type_de_champs: [{ type: :text, libelle: 'Titre de la publication' }])
    column = perso_procedure.customizable_columns.first
    create(:dossiers_list_personnalisation, user:, procedure: perso_procedure, displayed_columns: [column])
    dossiers = create_list(:dossier, 6, :en_construction, user:, procedure: perso_procedure, populate_champs: true)
    champ = dossiers.first.champs.find { _1.stable_id == column.stable_id }
    champ.update(value: 'Presse Océan')

    visit dossiers_path

    expect(page).to have_css('.fr-icon-info-i')
    expect(page).to have_text('Presse Océan')
  end

  it 'lets the user pick fields and persists the personnalisation' do
    visit dossiers_path

    expect(page).to have_css('.mes-dossiers-header__personnalisation', text: 'Personnaliser la liste des dossiers')
    find('.mes-dossiers-header__personnalisation').click

    expect(page).to have_content('Personnaliser la liste des dossiers')
    expect(page).to have_content(procedure.libelle)
    find('.dom-ready')

    expect(page).to have_button('Enregistrer', disabled: true)

    find('button.fr-select', match: :first).click

    expect(page).to have_css('.dropdown-section-header', text: 'Identité')
    expect(page).to have_css('[role="option"]', text: 'Nom du titre *')

    find('[role="option"]', text: 'Nom du titre').click
    find('[role="option"]', text: 'Numéro CPPAP').click
    send_keys(:escape)

    expect(page).to have_button('Enregistrer', disabled: false)

    click_button('Enregistrer')

    expect(page).to have_content('La liste des dossiers a bien été personnalisée.')

    perso = DossiersListPersonnalisation.find_by(user:, procedure:)
    expect(perso.displayed_columns.size).to eq(2)
  end
end
