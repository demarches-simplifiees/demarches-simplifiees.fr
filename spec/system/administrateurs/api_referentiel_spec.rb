# frozen_string_literal: true

describe 'Referentiel API:' do
  let(:zone) { create(:zone) }
  let(:service) { create(:service, administrateur:) }
  let(:procedure) { create(:procedure, :for_individual, types_de_champ_public:, zones: [zone], service:, administrateurs: [administrateur], instructeurs: [create(:instructeur)]) }
  let(:administrateur) { create(:administrateur, user: create(:user)) }
  let(:types_de_champ_public) do
    [
      { type: :textarea, libelle: 'un autre champ' },
      { type: :text, libelle: 'prefill with $.statut', stable_id: prefill_text_stable_id },
      { type: :checkbox, libelle: 'prefill with $.is_active', stable_id: prefill_boolean_stable_id }
    ]
  end
  let(:prefill_text_stable_id) { 42 }
  let(:prefill_boolean_stable_id) { 84 }

  before do
    login_as administrateur.user, scope: :user
  end

  scenario 'Setup as admin', js: true, vcr: true do
    Flipper.enable(:referentiel_type_de_champ, procedure)
    visit champs_admin_procedure_path(procedure)
    # add a second champ (when editing as user, need another champ to focus out of the referentiel champ which triggers autosave)
    within(all('.type-de-champ').last) do
      add_champ
    end
    expect(page).to have_selector('.type-de-champ-container', count: 4) # wait 4th champ added
    within(all('.type-de-champ-container').last) do
      select('Référentiel à configurer (avancé)', from: 'Type de champ')
      fill_in 'Libellé du champ', with: 'Nunero de bâtiment'
      click_on('Configurer le champ')
    end

    # configure connection
    VCR.use_cassette('referentiel/rnb_as_admin') do
      if Referentiels::APIReferentiel.csv_available?
        find('label[for="referentiel_type_referentielsapireferentiel"]').click
      end
      find("#referentiel_url").fill_in(with: 'google.com')
      expect(page).to have_content("n'est pas au format d'une URL, saisissez une URL valide ex https://api_1.ext/")
      find("#referentiel_url").fill_in(with: 'https://google.com')
      expect(page).to have_content("doit être autorisée par notre équipe. Veuillez nous contacter par mail (contact@demarches-simplifiees.fr) et nous indiquer l'URL et la documentation de l'API que vous souhaitez intégrer.")
      find("#referentiel_url").fill_in(with: 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/')
      if Referentiels::APIReferentiel.autocomplete_available?
        find('label[for="referentiel_mode_exact_match"]').click
      end
      fill_in("Indications à fournir à l’usager concernant le format de saisie attendu", with: "Saisir votre numero de bâtiment")
      fill_in("Exemple de saisie valide (affiché à l'usager et utilisé pour tester la requête)", with: "PG46YY6YWCX8")
      click_on('Étape suivante')
      expect(page).to have_content("Configuration du champ « Nunero de bâtiment » ")
    end

    # ensure response and configure mapping
    click_on("Afficher la réponse récupérée à partir de la requête configurée")
    expect(page).to have_content("PG46YY6YWCX8") # ensure api was called

    # checek prefill
    find("label[for=status]").click
    scroll_to(find_field('is_active'), align: :center)
    find("label[for=is_active]").click
    click_on('Étape suivante')

    # wait for next page load
    expect(page).to have_content("La configuration du mapping a bien été enregistrée")

    # then ensure choosen option are reflected on model
    referentiel_tdc = Referentiel.first.types_de_champ.first
    expect(referentiel_tdc.referentiel_mapping.dig("$.status", "prefill")).to eq("1")
    expect(referentiel_tdc.referentiel_mapping.dig("$.is_active", "prefill")).to eq("1")

    # ensure checked boxes enabled prefill opts
    expect(page).to have_content("$.status")
    expect(page).to have_content("$.is_active")

    # then choose another stable than the default one
    page.find("select[name='type_de_champ[referentiel_mapping][$.status][prefill_stable_id]']")
      .select('prefill with $.statut')

    # now should decide mapping
    click_on("Valider")
    referentiel_tdc.reload

    # back to champs and ensure it's considered as configured
    expect(page).to have_content("Configuré")

    # ensure referentiel deep option exists
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

    # start a dossier
    visit commencer_path(procedure.path)
    click_on("Commencer la démarche")
    expect(page).to have_content("Votre identité")
    find('label', text: 'Madame').click
    fill_in("Prénom", with: "Jeanne")
    fill_in("Nom", with: "Dupont")
    within "#identite-form" do
      click_on 'Continuer'
    end

    expect(page).to have_content("Identité enregistrée")
    expect(page).to have_css('label', text: "Nunero de bâtiment")

    # fill in champ
    fill_in("Nunero de bâtiment", with: "okokok")
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
      fill_in("Nunero de bâtiment", with: "kthxbye")
      fill_in("un autre champ", with: "focus out for autosave")

      perform_enqueued_jobs do
        # then the API response is fetched and tada... another error : bad data -> error
        expect(page).to have_content("Résultat introuvable. Vérifiez vos informations.")
      end
    end

    # success search
    VCR.use_cassette('referentiel/rnb_as_user') do
      fill_in("Nunero de bâtiment", with: "PG46YY6YWCX8")
      perform_enqueued_jobs do
        expect(page).to have_content("Référence trouvée : PG46YY6YWCX8")
        dossier = Dossier.last
        # check prefill in db
        expect(dossier.project_champs.find(&:referentiel?).value).to eq("PG46YY6YWCX8")
        expect(dossier.project_champs.find(&:checkbox?).value).to eq("true")
        expect(dossier.project_champs.find(&:text?).value).to eq("constructed")

        # check prefill reported in ui
        expect(page).to have_selector("##{dossier.project_champs.find(&:checkbox?).input_id}[value='true'][checked]")
        expect(page).to have_selector("##{dossier.project_champs.find(&:text?).input_id}[value='constructed']")
        expect(page).to have_content("Donnée remplie automatiquement.", count: 2)
      end
    end
  end
end
