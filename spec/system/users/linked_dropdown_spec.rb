describe 'linked dropdown lists' do
  let(:password) { 'my-s3cure-p4ssword' }
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

  let!(:procedure) do
    create(:procedure, :published, :for_individual, types_de_champ: [type_de_champ])
  end
  let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, libelle: 'linked dropdown', drop_down_list_value: list_items, mandatory: mandatory) }

  let(:user_dossier) { user.dossiers.first }
  context 'not mandatory' do
    let(:mandatory) { false }
    scenario 'change primary value, secondary options are updated', js: true do
      log_in(user.email, password, procedure)

      fill_individual
      expect(page).to have_select("linked dropdown", options: ['', 'Primary 1', 'Primary 2'])

      # Select a primary value
      select('Primary 2', from: 'linked dropdown')

      # Secondary menu reflects chosen primary value
      expect(page).to have_select("Valeur secondaire dépendant de la première", options: ['', 'Secondary 2.1', 'Secondary 2.2', 'Secondary 2.3'])

      # Select another primary value
      select('Primary 1', from: 'linked dropdown')

      # Secondary menu gets updated
      expect(page).to have_select("Valeur secondaire dépendant de la première", options: ['', 'Secondary 1.1', 'Secondary 1.2'])
    end
  end

  context 'mandatory' do
    let(:mandatory) { true }

    scenario 'change primary value, secondary options are updated', js: true do
      log_in(user.email, password, procedure)

      fill_individual
      expect(page).to have_select("linked dropdown", options: ['', 'Primary 1', 'Primary 2'])

      # Select a primary value
      select('Primary 2', from: 'linked dropdown')

      # Secondary menu reflects chosen primary value
      expect(page).to have_select("Valeur secondaire dépendant de la première", options: ['', 'Secondary 2.1', 'Secondary 2.2', 'Secondary 2.3'])

      # Select another primary value
      select('Primary 1', from: 'linked dropdown')

      # Secondary menu gets updated
      expect(page).to have_select("Valeur secondaire dépendant de la première", options: ['', 'Secondary 1.1', 'Secondary 1.2'])
    end
  end

  private

  def log_in(email, password, procedure)
    visit "/commencer/#{procedure.path}"
    click_on 'J’ai déjà un compte'

    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password)

    expect(page).to have_current_path(commencer_path(path: procedure.path))
    click_on 'Commencer la démarche'

    expect(page).to have_content("Données d’identité")
    expect(page).to have_current_path(identite_dossier_path(user_dossier))
  end

  def fill_individual
    choose 'Monsieur'
    fill_in('individual_prenom', with: 'prenom')
    fill_in('individual_nom', with: 'nom')
    click_on 'Continuer'
    expect(page).to have_current_path(brouillon_dossier_path(user_dossier))
  end
end
