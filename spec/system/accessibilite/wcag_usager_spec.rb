describe 'wcag rules for usager', js: true do
  let(:procedure) { create(:procedure, :published, :with_all_champs, :with_service, :for_individual) }
  let(:password) { 'a very complicated password' }
  let(:litteraire_user) { create(:user, password: password) }

  before do
    procedure.active_revision.types_de_champ_public.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:carte) }.destroy
  end

  shared_examples "external links have title says it opens in a new tab" do
    it do
      links = page.all("a[target=_blank]")
      expect(links.count).to be_positive

      links.each do |link|
        expect(link[:title]).to include("Nouvel onglet"), "link #{link[:href]} does not have title mentioning it opens in a new tab"
      end
    end
  end

  shared_examples "aria-label do not mix with title attribute" do
    it do
      elements = page.all("[aria-label][title]")
      elements.each do |element|
        expect(element[:title]).to be_blank, "path=#{path}, element title=\"#{element[:title]}\" mixes aria-label and title attributes"
      end
    end
  end

  context 'pages without the need to be logged in' do
    before do
      visit path
    end

    context 'homepage' do
      let(:path) { root_path }
      it { expect(page).to be_axe_clean }
      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
    end

    context 'sign_up page' do
      let(:path) { new_user_registration_path }
      it { expect(page).to be_axe_clean }
      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
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

    context 'sign_upc confirmation' do
      let(:path) { user_confirmation_path("user[email]" => "some@email.com") }

      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
    end

    context 'sign_in page' do
      let(:path) { new_user_session_path }
      it { expect(page).to be_axe_clean.excluding '#user_email' }
      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
    end

    context 'contact page' do
      let(:path) { contact_path }
      it { expect(page).to be_axe_clean }
      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
    end

    context 'commencer page' do
      let(:path) { commencer_path(path: procedure.path) }
      it { expect(page).to be_axe_clean }
      it_behaves_like "external links have title says it opens in a new tab"
      it_behaves_like "aria-label do not mix with title attribute"
    end

    scenario 'commencer page, help dropdown' do
      visit commencer_path(path: procedure.reload.path)

      page.find("#help-menu_button").click
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

      expect(page).to be_axe_clean
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
      expect(page).to be_axe_clean
    end
  end

  context "logged in, avec des dossiers déposés" do
    let(:dossier) { create(:dossier, procedure: procedure, user: litteraire_user) }
    before do
      login_as litteraire_user, scope: :user
    end

    scenario 'liste des dossiers sans dossiers' do
      visit dossiers_path
      expect(page).to be_axe_clean
    end

    scenario 'liste des dossiers avec des dossiers' do
      dossier
      visit dossiers_path
      expect(page).to be_axe_clean
    end

    scenario 'liste des dossiers et actions sur le dossier' do
      dossier
      visit dossiers_path
      page.find("#actions_menu_dossier_#{dossier.id}_button").click
      expect(page).to be_axe_clean
    end

    scenario 'dossier' do
      visit dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'merci' do
      visit merci_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'demande' do
      visit demande_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'messagerie avec des messages' do
      create(:commentaire, dossier: dossier, instructeur: procedure.instructeurs.first, body: 'hello')
      create(:commentaire, dossier: dossier, email: dossier.user.email, body: 'hello')
      visit messagerie_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'modifier' do
      visit modifier_dossier_path(dossier)
      expect(page).to be_axe_clean
    end

    scenario 'brouillon' do
      visit brouillon_dossier_path(dossier)
      expect(page).to be_axe_clean
    end
  end
end
