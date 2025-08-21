# frozen_string_literal: true

describe 'Referentiel API:' do
  let(:zone) { create(:zone) }
  let(:user) { create(:user) }
  let(:administrateur) { create(:administrateur, user:) }
  let(:instructeur) { administrateur.instructeur }
  let(:service) { create(:service, administrateur:) }
  let!(:procedure) { create(:procedure, :for_individual, types_de_champ_public:, zones: [zone], service:, administrateurs: [administrateur], instructeurs: [instructeur]) }
  let(:referentiel_stable_id) { 21 }
  let(:prefill_text_stable_id) { 42 }

  before do
    Instructeur.where(user:).where.not(id: instructeur.id).destroy_all # remove other instructeurs
    login_as instructeur.user, scope: :user
  end

  context 'safely select url' do
    let(:types_de_champ_public) do
      [
        { type: :referentiel, libelle: "qu'importe" }
      ]
    end
    scenario 'Setup as admin, fails with invalid url', js: true do
      visit champs_admin_procedure_path(procedure)
      click_on('Configurer le champ')

      find("#referentiel_url").fill_in(with: 'google.com')
      expect(page).to have_content("n'est pas au format d'une URL, saisissez une URL valide ex https://api_1.ext/")
      find("#referentiel_url").fill_in(with: 'https://google.com')
      expect(page).to have_content("doit être autorisée par notre équipe. Veuillez nous contacter par mail (contact@demarches-simplifiees.fr) et nous indiquer l'URL et la documentation de l'API que vous souhaitez intégrer.")
      find("#referentiel_url").fill_in(with: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/')
      expect(page).to have_content("Attention si vous appelez une API qui renvoie de la donnée personnelle, vous devez en informer votre DPO.")
    end
  end

  context 'exact_match' do
    let(:prefill_boolean_stable_id) { 84 }
    let(:prefill_repetition_children_stable_id) { 168 }
    let(:types_de_champ_public) do
      [
        { type: :referentiel, libelle: 'Numero de bâtiment', stable_id: referentiel_stable_id },
        { type: :textarea, libelle: 'un autre champ' },
        { type: :text, libelle: 'prefill with $.statut', stable_id: prefill_text_stable_id },
        { type: :checkbox, libelle: 'prefill with $.is_active', stable_id: prefill_boolean_stable_id },
        {
          type: :repetition,
          libelle: "repetition",
          mandatory: false,
          children: [
            { type: :text, libelle: 'prefill with $.addresses[0].street', stable_id: prefill_repetition_children_stable_id }
          ]
        }
      ]
    end

    scenario 'Setup as admin, fill in as user, view it as instructeur', js: true, vcr: true do
      visit champs_admin_procedure_path(procedure)
      click_on('Configurer le champ')

      # configure connection
      VCR.use_cassette('referentiel/rnb_as_admin') do
        find("#referentiel_url").fill_in(with: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/')
        find('label[for="referentiel_mode_exact_match"]').click
        fill_in("Indications à fournir à l’usager concernant le format de saisie attendu", with: "Saisir votre numero de bâtiment")
        fill_in("Exemple de saisie valide (affiché à l'usager et utilisé pour tester la requête)", with: "PG46YY6YWCX8")
        click_on('Étape suivante')
        wait_until { Referentiel.count == 1 }
        expect(page).to have_content("Pré remplissage des champs et/ou affichage des données récupérées")
      end
      # check response and configure mapping
      click_on("Afficher la réponse récupérée à partir de la requête configurée")
      expect(page).to have_content("PG46YY6YWCX8") # check api was called

      #
      # map prefilled champs
      #
      custom_check("status")
      custom_check('is_active')
      custom_check('addresses-0-street')

      ## fill a custom libelle to display to user
      fill_in("type_de_champ_referentiel_mapping__.point.coordinates_libelle", with: "Coordonées du point")
      fill_in("type_de_champ_referentiel_mapping__.point.type_libelle", with: "Type de point")

      # submit and check values
      click_on('Étape suivante')
      expect(page).to have_content("La configuration du mapping a bien été enregistrée")
      referentiel_tdc = Referentiel.first.types_de_champ.first
      expect(referentiel_tdc.referentiel_mapping.dig("$.status", "prefill")).to eq("1")
      expect(referentiel_tdc.referentiel_mapping.dig("$.is_active", "prefill")).to eq("1")

      ##
      # choose prefill stable ids
      ###
      expect(page).to have_content("$.status")
      page.find("select[name='type_de_champ[referentiel_mapping][$.status][prefill_stable_id]']")
        .select('prefill with $.statut')
      # one boolean champ, nothing to select
      expect(page).to have_content("$.is_active")
      # choose another stable than the default one for the repetition
      expect(page).to have_content("$.addresses[0].street")
      page.find("select[name='type_de_champ[referentiel_mapping][$.addresses{0}.street][prefill_stable_id]']")
        .select('repetition - prefill with $.addresses[0].street')
      ##
      # choose display_usager display_instructeur
      ###
      # choose string value for usager and instructeur
      custom_check('point-type-display_usager')
      custom_check('point-type-display_instructeur')
      # choose array values only for usager
      custom_check('point-coordinates-display_usager')
      # choose string value only instructeur
      custom_check('shape-type-display_instructeur')
      click_on("Valider")

      wait_until { referentiel_tdc.reload .referentiel_mapping.dig("$.status", "prefill_stable_id").present? }
      # back to champs and check it's considered as configured
      expect(page).to have_content("Configuré")

      # check referentiel deep option exists
      expect(referentiel_tdc.referentiel_mapping.dig("$.status", "prefill_stable_id").to_s).to eq(prefill_text_stable_id.to_s)
      expect(referentiel_tdc.referentiel_mapping.dig("$.is_active", "prefill_stable_id").to_s).to eq(prefill_boolean_stable_id.to_s)
      # now procedure should be publishable
      visit admin_procedure_path(procedure)
      click_on("Publier")

      # publish
      find("#procedure_path").fill_in(with: "htxbye")
      find("#lien_site_web").fill_in(with: "google.fr")
      within(".form") do
        click_on("Publier")
      end
      wait_until { procedure.reload.published_revision.present? }

      # start a dossier
      visit commencer_path(procedure.path)
      click_on("Commencer la démarche")
      expect(page).to have_content("Votre identité")
      fill_in("Prénom", with: "Jeanne")
      fill_in("Nom", with: "Dupont")
      within "#identite-form" do
        click_on 'Continuer'
      end

      expect(page).to have_content("Identité enregistrée")

      # fill in champ
      fill_in("Numero de bâtiment", with: "okokok")
      fill_in("un autre champ", with: "focus out for autosave")
      # update champ should not trigger an error and render a feedback
      expect(page).to have_content("Recherche en cours.")

      # but submitting bef  ore API response was fetched should trigger an error
      click_on("Déposer le dossier")
      expect(page).to have_content("En attente de réponse...")

      # reload page, if API response was not fetched, it's an error
      visit dossier_path(Dossier.last)
      expect(page).to have_content("En attente de réponse...")

      # and the page starts polling
      expect(page).to have_content("Recherche en cours.")

      # failed search
      VCR.use_cassette('referentiel/kthxbye_as_user') do
        fill_in("Numero de bâtiment", with: "kthxbye")
        fill_in("un autre champ", with: "focus out for autosave")

        perform_enqueued_jobs do
          # then the API response is fetched and tada... another error : bad data -> error
          expect(page).to have_content("Résultat introuvable. Vérifiez vos informations.")
        end
      end

      # success search
      VCR.use_cassette('referentiel/rnb_as_user') do
        fill_in("Numero de bâtiment", with: "PG46YY6YWCX8")
        perform_enqueued_jobs do
          expect(page).to have_content("Référence trouvée : PG46YY6YWCX8")
          dossier = Dossier.last

          # check prefill values in db
          expect(dossier.project_champs_public_all.find { it.stable_id.to_s == referentiel_stable_id.to_s }.value).to eq("PG46YY6YWCX8")
          expect(dossier.project_champs_public_all.find { it.stable_id.to_s == prefill_text_stable_id.to_s }.value).to eq("constructed")
          expect(dossier.project_champs_public_all.find { it.stable_id.to_s == prefill_boolean_stable_id.to_s }.value).to eq("true")
          repetition_values = dossier.project_champs_public_all.filter { it.stable_id.to_s == prefill_repetition_children_stable_id.to_s }.map(&:value)
          expect(repetition_values).to include("rue du puits")
          expect(repetition_values).to include("place de la bourse")

          # check webpage was also updated
          expect(page).to have_content("Donnée remplie automatiquement.", count: 4)

          # check display_usager populated web page too
          page.find("button[aria-controls=display_usager]").click
          within(".fr-collapse#display_usager") do
            # now we check that the filled libelle for the mapping and the value are in the webpage, with the accordion
            expect(page).to have_content("Coordonées du point : -0.570505392116188, 44.841034137099996")
            expect(page).to have_content("Type de point : Point")
          end

          # check we can create a dossier
          click_on("Déposer le dossier")
          wait_until { Dossier.en_construction.count == 1 }

          created_dossier = Dossier.last
          # check data is also visible on demande page as an usager
          visit demande_dossier_path(created_dossier)
          expect(page).to have_content("Coordonées du point : -0.570505392116188, 44.841034137099996")
          expect(page).to have_content("Type de point : Point")
          expect(page).not_to have_content("$.shape.type") # not displayed to usager

          # check data is also visible on demande page as an usager
          visit instructeur_dossier_path(procedure, created_dossier)
          expect(page).to have_content("Sections du formulaire")
          expect(page).not_to have_content("Coordonées du point")
          expect(page).to have_content("Type de point")
          expect(page).to have_content("$.shape.type")
        end
      end
    end
  end

  context 'autocomplete' do
    let(:types_de_champ_public) do
        [
          { type: :referentiel, libelle: 'Numéro FINESS', stable_id: referentiel_stable_id },
          { type: :textarea, libelle: 'un autre champ' },
          { type: :text, libelle: 'prefill with $.source', stable_id: prefill_text_stable_id },
          { type: :checkbox, libelle: 'prefill with $.date_extract_finess', stable_id: prefill_date_stable_id }
        ]
      end
    let(:prefill_date_stable_id) { 84 }

    scenario 'Setup as admin, fill in as user, view it as instructeur', js: true, vcr: true do
      visit champs_admin_procedure_path(procedure)
      click_on('Configurer le champ')

      # configure connection
      VCR.use_cassette('referentiel/datagouv-finess') do
        find("#referentiel_url").fill_in(with: 'https://tabular-api.data.gouv.fr/api/resources/796dfff7-cf54-493a-a0a7-ba3c2024c6f3/data/?finess__contains={id}')
        find('label[for="referentiel_mode_autocomplete"]').click
        fill_in("Indications à fournir à l’usager concernant le format de saisie attendu", with: "Saisir votre finess")
        fill_in("Exemple de saisie valide (affiché à l'usager et utilisé pour tester la requête)", with: "010002699")
        click_on('Étape suivante')
        wait_until { Referentiel.count == 1 }
        expect(page).to have_content("Configuration de l'autocomplétion ")
      end
    end
  end

  scenario 'setup back/forth auth', js: true do
    visit champs_admin_procedure_path(procedure)
    click_on('Configurer le champ')
    expect(page).to have_unchecked_field("Ajouter une méthode d’authentification")
    find("#referentiel_url").fill_in(with: 'google.com')
    expect(page).to have_content("Le champ « URL de l'API » n'est pas au format d'une URL, saisissez une URL valide ex https://api_1.ext/")
    expect(page).to have_unchecked_field("Ajouter une méthode d’authentification")
  end
end
