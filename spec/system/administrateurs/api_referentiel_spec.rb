# frozen_string_literal: true

describe 'Referentiel API:' do
  let(:zone) { create(:zone) }
  let(:service) { create(:service, administrateur:) }
  let(:procedure) { create(:procedure, :for_individual, types_de_champ_public:, zones: [zone], service:, administrateurs: [administrateur], instructeurs: [create(:instructeur)]) }
  let(:administrateur) { create(:administrateur, user: create(:user)) }
  let(:types_de_champ_public) { [{ type: :text, libelle: 'un autre champ' }] }

  before do
    login_as administrateur.user, scope: :user
  end

  scenario 'Setup as admin', js: true, vcr: true do
    Flipper.enable(:referentiel_type_de_champ, procedure)
    visit champs_admin_procedure_path(procedure)

    # add a second champ (when editing as user, need another champ to focus out of the referentiel champ which triggers autosave)
    within(find('.type-de-champ-add-button', match: :first)) do
      add_champ
    end
    expect(page).to have_selector('.type-de-champ-container', count: 2) # wait 2nd champ added
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

    # check response and configure mapping
    click_on("Afficher la réponse récupérée à partir de la requête configurée")
    expect(page).to have_content("PG46YY6YWCX8") # ensure api was called
    click_on('Étape suivante')

    # ensure it was setup as expected
    expect(page).to have_content("La configuration du mapping a bien été enregistrée")

    # back to champs and ensure it's considered as configured
    click_on("Champs du formulaire")
    expect(page).to have_content("Configuré")

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
      end
    end
  end
end
