require 'spec_helper'

feature 'linked dropdown lists' do
  let(:password) { 'secret_password' }
  let!(:user) { create(:user, password: password) }

  let(:list_items) do
    <<~END_OF_LIST
      --Master 1--
      Slave 1.1
      Slave 1.2
      --Master 2--
      Slave 2.1
      Slave 2.2
      Slave 2.3
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

  scenario 'change master value, slave options are updated', js: true do
    log_in(user.email, password, procedure)

    fill_individual

    # Select a master value
    select('Master 2', from: master_id_for('linked dropdown'))

    # Slave menu reflects chosen master value
    expect(page).to have_select(slave_id_for('linked dropdown'), options: ['', 'Slave 2.1', 'Slave 2.2', 'Slave 2.3'])

    # Select another master value
    select('Master 1', from: master_id_for('linked dropdown'))

    # Slave menu gets updated
    expect(page).to have_select(slave_id_for('linked dropdown'), options: ['', 'Slave 1.1', 'Slave 1.2'])
  end

  private

  def log_in(email, password, procedure)
    visit "/commencer/#{procedure.procedure_path.path}"
    expect(page).to have_current_path(new_user_session_path)

    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_on 'Se connecter'
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def fill_individual
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    check 'dossier_autorisation_donnees'
    click_on 'Continuer'
    expect(page).to have_current_path(modifier_dossier_path(user_dossier))
  end

  def master_id_for(libelle)
    find(:xpath, ".//label[contains(text()[normalize-space()], '#{libelle}')]")[:for]
  end

  def slave_id_for(libelle)
    master_id = master_id_for(libelle)
    link = find("\##{master_id}")['data-master-id']
    find("[data-slave-id=\"#{link}\"]")['id']
  end
end
