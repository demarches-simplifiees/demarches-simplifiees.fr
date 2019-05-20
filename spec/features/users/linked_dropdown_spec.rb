require 'spec_helper'

feature 'linked dropdown lists' do
  let(:password) { 'déMarches-simPlifiées-pwd' }
  let!(:user) { create(:user, password: password) }

  let(:list_items) do
    <<~END_OF_LIST
      --Primary 1--
      Secondary 1.1
      Secondary 1.2
      --Primary 2--
      Secondary 2.1
      Secondary 2.2
      Secondary 2.3
    END_OF_LIST
  end
  let(:drop_down_list) { create(:drop_down_list, value: list_items) }
  let(:type_de_champ) { create(:type_de_champ_linked_drop_down_list, libelle: 'linked dropdown', drop_down_list: drop_down_list) }

  let!(:procedure) do
    p = create(:procedure, :published, :for_individual)
    p.types_de_champ << type_de_champ
    p
  end

  let(:user_dossier) { user.dossiers.first }

  scenario 'change primary value, secondary options are updated', js: true do
    log_in(user.email, password, procedure)

    fill_individual

    # Select a primary value
    select('Primary 2', from: primary_id_for('linked dropdown'))

    # Secondary menu reflects chosen primary value
    expect(page).to have_select(secondary_id_for('linked dropdown'), options: ['', 'Secondary 2.1', 'Secondary 2.2', 'Secondary 2.3'])

    # Select another primary value
    select('Primary 1', from: primary_id_for('linked dropdown'))

    # Secondary menu gets updated
    expect(page).to have_select(secondary_id_for('linked dropdown'), options: ['', 'Secondary 1.1', 'Secondary 1.2'])
  end

  private

  def log_in(email, password, procedure)
    visit "/commencer/#{procedure.path}"
    click_on 'J’ai déjà un compte'

    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password)

    expect(page).to have_current_path(commencer_path(path: procedure.path))
    click_on 'Commencer la démarche'

    expect(page).to have_content("Données d'identité")
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def fill_individual
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    click_on 'Continuer'
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end

  def primary_id_for(libelle)
    find(:xpath, ".//label[contains(text()[normalize-space()], '#{libelle}')]")[:for]
  end

  def secondary_id_for(libelle)
    primary_id = primary_id_for(libelle)
    find("\##{primary_id}")
      .ancestor('.editable-champ')
      .find("[data-secondary]")['id']
  end
end
