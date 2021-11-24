describe 'fetch API Particulier Data', js: true do
  let(:administrateur) { create(:administrateur) }

  let(:expected_token) { 'd7e9c9f4c3ca00caadde31f50fd4521a' }

  let(:expected_sources) do
    {
      'cnaf' =>
      {
        'adresse' => ['identite', 'complementIdentite', 'complementIdentiteGeo', 'numeroRue', 'lieuDit', 'codePostalVille', 'pays'],
        'allocataires' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
        'enfants' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
        'quotient_familial' => ['quotientFamilial', 'annee', 'mois']
      },
      'dgfip' =>
      {
        'declarant1' => ['dateNaissance', 'nom', 'nomNaissance', 'prenoms'],
        'declarant2' => ['dateNaissance', 'nom', 'nomNaissance', 'prenoms'],
        'echeance_avis' => ['dateEtablissement', 'dateRecouvrement'],
        'foyer_fiscal' => ['adresse', 'annee', 'nombreParts', 'nombrePersonnesCharge', 'situationFamille'],
        'agregats_fiscaux' => ['anneeImpots', 'anneeRevenus', 'impotRevenuNetAvantCorrections', 'montantImpot', 'revenuBrutGlobal', 'revenuFiscalReference', 'revenuImposable'],
        'complements' => ['situationPartielle', 'erreurCorrectif']
      }
    }
  end

  before do
    stub_const('API_PARTICULIER_URL', 'https://particulier.api.gouv.fr/api')
    Flipper.enable(:api_particulier)
  end

  context 'when an administrateur is logged' do
    let(:procedure) do
      create(:procedure, :with_service, :with_instructeur,
             aasm_state: :brouillon,
             administrateurs: [administrateur],
             libelle: 'libellé de la procédure',
             path: 'libelle-de-la-procedure')
    end

    before { login_as administrateur.user, scope: :user }

    scenario 'it can enable api particulier' do
      visit admin_procedure_path(procedure)
      expect(page).to have_content('Configurer le jeton API particulier')

      find('#api-particulier').click
      expect(page).to have_current_path(admin_procedure_api_particulier_path(procedure))

      find('#add-jeton').click
      expect(page).to have_current_path(admin_procedure_api_particulier_jeton_path(procedure))

      fill_in 'procedure_api_particulier_token', with: expected_token
      VCR.use_cassette('api_particulier/success/introspect') { click_on 'Enregistrer' }
      expect(page).to have_text('Le jeton a bien été mis à jour')
      expect(page).to have_current_path(admin_procedure_api_particulier_sources_path(procedure))

      ['allocataires', 'enfants'].each do |scope|
        within("##{scope}") do
          check('noms et prénoms')
          check('date de naissance')
          check('sexe')
        end
      end

      within('#adresse') do
        check('identité')
        check('complément d’identité')
        check('complément d’identité géographique')
        check('numéro et rue')
        check('lieu-dit')
        check('code postal et ville')
        check('pays')
      end

      within('#quotient_familial') do
        check('quotient familial')
        check('année')
        check('mois')
      end

      ['declarant1', 'declarant2'].each do |scope|
        within("##{scope}") do
          check('nom')
          check('nom de naissance')
          check('prénoms')
          check('date de naissance')
        end
      end

      scroll_to(find('#echeance_avis'))
      within ('#echeance_avis') do
        check('date de recouvrement')
        check("date d’établissement")
      end

      within('#foyer_fiscal') do
        check('année')
        check('adresse')
        check('nombre de parts')
        check('situation familiale')
        check('nombre de personnes à charge')
      end

      within('#agregats_fiscaux') do
        check('revenu brut global')
        check('revenu imposable')
        check('impôt sur le revenu net avant correction')
        check("montant de l’impôt")
        check('revenu fiscal de référence')
        check("année d’imposition")
        check('année des revenus')
      end

      within('#complements') do
        check('erreur correctif')
        check('situation partielle')
      end

      click_on 'Enregistrer'

      within('#enfants') do
        expect(find('input[value=nomPrenom]')).to be_checked
      end

      procedure.reload

      expect(procedure.api_particulier_sources.keys).to contain_exactly('cnaf', 'dgfip')
      expect(procedure.api_particulier_sources['cnaf'].keys).to contain_exactly('adresse', 'allocataires', 'enfants', 'quotient_familial')
      expect(procedure.api_particulier_sources['dgfip'].keys).to contain_exactly('declarant1', 'declarant2', 'echeance_avis', 'foyer_fiscal', 'agregats_fiscaux', 'complements')

      procedure.api_particulier_sources.each do |provider, scopes|
        scopes.each do |scope, fields|
          expect(fields).to match_array(expected_sources[provider][scope])
        end
      end

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
    let(:numero_fiscal) { '2097699999077' }
    let(:reference_avis) { '2097699999077' }
    let(:instructeur) { create(:instructeur) }

    let(:procedure) do
      create(:procedure, :for_individual, :with_service, :with_cnaf, :with_dgfip, :published,
             libelle: 'libellé de la procédure',
             path: 'libelle-de-la-procedure',
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

      VCR.use_cassette('api_particulier/success/composition_familiale') do
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

    scenario 'it can fill a DGFiP field' do
      visit commencer_path(path: procedure.path)
      click_on 'Commencer la démarche'

      choose 'Madame'
      fill_in 'individual_nom',    with: 'FERRI'
      fill_in 'individual_prenom', with: 'Karine'

      click_button('Continuer')

      fill_in 'Le numéro fiscal', with: numero_fiscal
      fill_in "La référence d'avis d'imposition", with: 'wrong_code'

      blur
      expect(page).to have_css('span', text: 'Brouillon enregistré', visible: true)

      dossier = Dossier.last
      expect(dossier.champs.second.reference_avis).to eq('wrong_code')

      click_on 'Déposer le dossier'
      expect(page).to have_content(/reference avis doit posséder 13 ou 14 caractères/)

      fill_in "La référence d'avis d'imposition", with: reference_avis

      VCR.use_cassette('api_particulier/success/avis_imposition') do
        perform_enqueued_jobs { click_on 'Déposer le dossier' }
      end

      visit demande_dossier_path(dossier)
      expect(page).to have_content(/Des données.*ont été reçues depuis la DGFiP/)

      log_out

      login_as instructeur.user, scope: :user

      visit instructeur_dossier_path(procedure, dossier)

      expect(page).to have_content('nom FERRI')
      expect(page).to have_content('nom de naissance FERRI')
      expect(page).to have_content('prénoms Karine')
      expect(page).to have_content('date de naissance 12/08/1978')

      expect(page).to have_content('date de recouvrement 09/10/2020')
      expect(page).to have_content("date d’établissement 07/07/2020")

      expect(page).to have_content('année 2020')
      expect(page).to have_content("adresse fiscale de l’année passée 13 rue de la Plage 97615 Pamanzi")
      expect(page).to have_content('nombre de parts 1')
      expect(page).to have_content('situation familiale Célibataire')
      expect(page).to have_content('nombre de personnes à charge 0')

      expect(page).to have_content('revenu brut global 38814')
      expect(page).to have_content('revenu imposable 38814')
      expect(page).to have_content('impôt sur le revenu net avant correction 38814')
      expect(page).to have_content("montant de l’impôt 38814")
      expect(page).to have_content('revenu fiscal de référence 38814')
      expect(page).to have_content("année d’imposition 2020")
      expect(page).to have_content('année des revenus 2020')

      expect(page).to have_content('situation partielle SUP DOM')

      expect(page).not_to have_content('erreur correctif')
    end
  end
end
