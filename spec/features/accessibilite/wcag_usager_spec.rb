feature 'wcag rules for usager', js: true do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_all_champs, :with_service, :for_individual, :published) }
  let(:password) { 'a very complicated password' }
  let(:litteraire_user) { create(:user, password: password) }

  before do
    procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:carte) }.destroy
  end

  context 'pages without the need to be logged in' do
    scenario 'homepage' do
      visit root_path
      expect(page).to be_axe_clean
    end

    scenario 'sign_up page' do
      visit new_user_registration_path
      expect(page).to be_axe_clean
    end

    scenario 'account confirmation page' do
      visit new_user_registration_path

      fill_in :user_email, with: "some@email.com"
      fill_in :user_password, with: "epeciusetuir"

      perform_enqueued_jobs do
        click_button 'Créer un compte'
        expect(page).to be_axe_clean
      end
    end

    scenario 'sign_in page' do
      visit new_user_session_path
      expect(page).to be_axe_clean.excluding '#user_email'
    end

    scenario 'contact page' do
      visit contact_path
      expect(page).to be_axe_clean
    end

    scenario 'commencer page' do
      visit commencer_path(path: procedure.reload.path)
      expect(page).to be_axe_clean
    end
  end

  context "logged in, depot d'un dossier as individual" do
    before do
      login_as litteraire_user, scope: :user
      visit commencer_path(path: procedure.reload.path)
    end

    scenario 'écran identité usager' do
      click_on 'Commencer la démarche'
      expect(page).to be_axe_clean
    end

    # with no surprise, there's a lot of work on this one
    scenario "dépot d'un dossier" do
      click_on 'Commencer la démarche'

      choose 'Monsieur'
      fill_in('individual_prenom', with: 'prenom')
      fill_in('individual_nom', with: 'nom')
      click_on 'Continuer'

      expect(page).to be_axe_clean.skipping :'aria-input-field-name'
    end
  end

  context "logged in, depot d'un dossier entreprise" do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_all_champs, :with_service, :published) }

    before do
      login_as litteraire_user, scope: :user
      visit commencer_path(path: procedure.reload.path)
    end

    scenario "écran identification de l'entreprise" do
      click_on 'Commencer la démarche'
      expect(page).to be_axe_clean.skipping :label
    end
  end

  context "logged in, avec des dossiers dossiers déposés" do
    let(:dossier) { create(:dossier, procedure: procedure, user: litteraire_user) }
    before do
      login_as litteraire_user, scope: :user
    end

    scenario 'liste des dossiers' do
      visit dossiers_path
      expect(page).to be_axe_clean
    end

    scenario 'dossier' do
      visit dossier_path(dossier)
      expect(page).to be_axe_clean.skipping :'aria-input-field-name'
    end

    scenario 'merci' do
      visit merci_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'demande' do
      visit demande_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'messagerie' do
      visit messagerie_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'modifier' do
      visit modifier_dossier_path(dossier)
      expect(page).to be_axe_clean.skipping :'aria-input-field-name'
    end

    scenario 'brouillon' do
      visit brouillon_dossier_path(dossier)
      expect(page).to be_axe_clean.skipping :'aria-input-field-name'
    end
  end
end
