describe 'fetch API Particulier Data', js: true do
  let(:administrateur) { create(:administrateur) }

  let(:expected_token) { 'd7e9c9f4c3ca00caadde31f50fd4521a' }

  let(:expected_sources) do
    {
      "cnaf" =>
      {
        "adresse" => ["identite", "complementIdentite", "complementIdentiteGeo", "numeroRue", "lieuDit", "codePostalVille", "pays"],
        "allocataires" => ["nomPrenom", "dateDeNaissance", "sexe"],
        "enfants" => ["nomPrenom", "dateDeNaissance", "sexe"],
        "quotient_familial" => ["quotientFamilial", "annee", "mois"]
      }
    }
  end

  before do
    stub_const("API_PARTICULIER_URL", "https://particulier.api.gouv.fr/api")
    Flipper.enable(:api_particulier)
  end

  context "when an administrateur is logged" do
    let(:procedure) do
      create(:procedure, :with_service, :with_instructeur,
             aasm_state: :brouillon,
             administrateurs: [administrateur],
             libelle: "libellé de la procédure",
             path: "libelle-de-la-procedure")
    end

    before { login_as administrateur.user, scope: :user }

    scenario 'it can enable api particulier' do
      visit admin_procedure_path(procedure)
      expect(page).to have_content("Configurer le jeton API particulier")

      find('#api-particulier').click
      expect(page).to have_current_path(admin_procedure_api_particulier_path(procedure))

      find('#add-jeton').click
      expect(page).to have_current_path(admin_procedure_api_particulier_jeton_path(procedure))

      fill_in 'procedure_api_particulier_token', with: expected_token
      VCR.use_cassette("api_particulier/success/introspect") { click_on 'Enregistrer' }
      expect(page).to have_text('Le jeton a bien été mis à jour')
      expect(page).to have_current_path(admin_procedure_api_particulier_sources_path(procedure))

      ['allocataires', 'enfants'].each do |scope|
        within("##{scope}") do
          check('noms et prénoms')
          check('date de naissance')
          check('sexe')
        end
      end

      within("#adresse") do
        check('identité')
        check('complément d’identité')
        check('complément d’identité géographique')
        check('numéro et rue')
        check('lieu-dit')
        check('code postal et ville')
        check('pays')
      end

      within("#quotient_familial") do
        check('quotient familial')
        check('année')
        check('mois')
      end

      click_on "Enregistrer"

      within("#enfants") do
        expect(find('input[value=nomPrenom]')).to be_checked
      end

      expect(procedure.reload.api_particulier_sources).to eq(expected_sources)

      visit champs_admin_procedure_path(procedure)

      add_champ
      select('Données de la Caisse nationale des allocations familiales', from: 'champ-0-type_champ')
      fill_in 'champ-0-libelle', with: 'libellé de champ'
      blur
      expect(page).to have_content('Formulaire enregistré')

      visit admin_procedure_path(procedure)
      find('#publish-procedure-link').click
      expect(find_field('procedure_path').value).to eq procedure.path
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'Publier'

      expect(page).to have_text('Démarche publiée')
    end
  end

  context 'when an user is logged' do
    let(:user) { create(:user) }
    let(:api_particulier_token) { '29eb50b65f64e8e00c0847a8bbcbd150e1f847' }
    let(:numero_allocataire) { '5843972' }
    let(:code_postal) { '92110' }
    let(:instructeur) { create(:instructeur) }

    let(:procedure) do
      create(:procedure, :for_individual, :with_service, :with_cnaf, :published,
             libelle: "libellé de la procédure",
             path: "libelle-de-la-procedure",
             instructeurs: [instructeur],
             api_particulier_sources: expected_sources,
             api_particulier_token: api_particulier_token)
    end

    before { login_as user, scope: :user }

    scenario 'it can fill an cnaf champ' do
      visit commencer_path(path: procedure.path)
      click_on 'Commencer la démarche'

      choose 'Monsieur'
      fill_in 'individual_nom',    with: 'Nom'
      fill_in 'individual_prenom', with: 'Prenom'

      click_button('Continuer')

      fill_in 'Le numéro d’allocataire CAF', with: numero_allocataire
      fill_in 'Le code postal', with: 'wrong_code'

      blur
      expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

      dossier = Dossier.last
      expect(dossier.champs.first.code_postal).to eq('wrong_code')

      click_on 'Déposer le dossier'
      expect(page).to have_content(/code postal doit posséder 5 caractères/)

      fill_in 'Le code postal', with: code_postal

      VCR.use_cassette("api_particulier/success/composition_familiale") do
        perform_enqueued_jobs { click_on 'Déposer le dossier' }
      end

      visit demande_dossier_path(dossier)
      expect(page).to have_content(/Des données.*ont été reçues depuis la CAF/)

      log_out

      login_as instructeur.user, scope: :user

      visit instructeur_dossier_path(procedure, dossier)

      expect(page).to have_content('code postal et ville 92110 Clichy')
      expect(page).to have_content('identité Mr SNOW Eric')
      expect(page).to have_content('complément d’identité ne connait rien')
      expect(page).to have_content('numéro et rue 109 rue La Boétie')
      expect(page).to have_content('pays FRANCE')
      expect(page).to have_content('complément d’identité géographique au nord de paris')
      expect(page).to have_content('lieu-dit glagla')
      expect(page).to have_content('ERIC SNOW masculin 07/01/1991')
      expect(page).to have_content('SANSA SNOW féminin 15/01/1992')
      expect(page).to have_content('PAUL SNOW masculin 04/01/2018')
      expect(page).to have_content('1856 6 2021')
    end
  end
end
