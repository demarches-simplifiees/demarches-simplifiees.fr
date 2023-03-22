namespace :anonymizer do
  desc "Inject pg_anonymizer dynamic rules. Rules can evolve over time so this tas is idempotent."
  task setup_rules: :environment do
    # First check if pg_anonymizer is installed
    result = ActiveRecord::Base.connection.execute "SELECT 1 as one FROM pg_extension WHERE extname = 'anon';"

    if result.count.zero?
      puts "Skip anonymizer:setup_rules because `anon` pg extension is not installed on this server."
      next
    end

    # grab super admin emails
    super_admin_emails = SuperAdmin.pluck(:email)

    sql_rules = [
      # fake emails
      "SECURITY LABEL FOR anon ON COLUMN avis.email IS 'MASKED WITH VALUE anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.email IS 'MASKED WITH VALUE anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN dossier_transfers.email IS 'MASKED WITH VALUE anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email IS 'MASKED WITH VALUE anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email_sender IS 'MASKED WITH VALUE anon.partial_email(email_sender)'",
      "SECURITY LABEL FOR anon ON COLUMN traitements.instructeur_email IS 'MASKED WITH VALUE anon.partial_email(instructeur_email)'",
      "SECURITY LABEL FOR anon ON COLUMN users.unconfirmed_email IS 'MASKED WITH FUNCTION anon.partial_email(unconfirmed_email)'",

      # users: partial emails except for super admins accounts, but ensure unicity
      "SECURITY LABEL FOR anon ON COLUMN users.email IS 'MASKED WITH VALUE CASE
                                                                           WHEN email IN (#{super_admin_emails.map { "$$#{_1}$$" }.join(',')}) THEN email
                                                                           ELSE CONCAT(id, $$+$$, anon.partial_email(email))
                                                                           END'",

      # partial emails
      "SECURITY LABEL FOR anon ON COLUMN email_events.to IS 'MASKED WITH VALUE anon.partial_email(email_events.to)'",

      # personal data
      "SECURITY LABEL FOR anon ON COLUMN individuals.nom IS 'MASKED WITH VALUE anon.fake_last_name()'",
      "SECURITY LABEL FOR anon ON COLUMN individuals.prenom IS 'MASKED WITH VALUE anon.fake_first_name()'",

      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.email_france_connect IS 'MASKED WITH VALUE anon.partial_email(email_france_connect)'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.family_name IS 'MASKED WITH VALUE anon.fake_last_name()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.france_connect_particulier_id IS 'MASKED WITH VALUE anon.random_string(2)'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.given_name IS 'MASKED WITH VALUE anon.fake_first_name()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.birthplace IS 'MASKED WITH VALUE anon.fake_city()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.merge_token IS 'MASKED WITH VALUE anon.random_string(2)'",

      # delayed jobs may contain sensitive data
      "SECURITY LABEL FOR anon ON COLUMN delayed_jobs.handler IS 'MASKED WITH VALUE NULL'",

      # etablissement - nullify everything, random siret and address with respect of degraded mode
      "SECURITY LABEL FOR anon ON COLUMN etablissements.siret IS 'MASKED WITH VALUE REPLACE(anon.fake_siret(), $$ $$, $$$$)'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.adresse IS 'MASKED WITH VALUE CASE
                                                                    WHEN adresse IS NULL THEN NULL
                                                                    ELSE anon.fake_address()
                                                                    END'",

      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_date_creation IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_date_declaration IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_date_publication IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_objet IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_rna IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.association_titre IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.code_insee_localite IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.code_postal IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.complement_adresse IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.diffusable_commercialement IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.enseigne IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_bilans_bdf IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_bilans_bdf_monnaie IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_capital_social IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_code_effectif_entreprise IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_date_creation IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_effectif_annee IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_effectif_annuel IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_effectif_annuel_annee IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_effectif_mensuel IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_effectif_mois IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_etat_administratif IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_forme_juridique IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_forme_juridique_code IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_nom IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_nom_commercial IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_numero_tva_intracommunautaire IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_prenom IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_raison_sociale IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_siren IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.entreprise_siret_siege_social IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.libelle_naf IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.localite IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.naf IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.nom_voie IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.numero_voie IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.siege_social IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.type_voie IS 'MASKED WITH VALUE NULL'",

      # various data
      "SECURITY LABEL FOR anon ON COLUMN active_storage_blobs.key IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN api_tokens.encrypted_token IS 'MASKED WITH VALUE anon.random_string(5)'",
      "SECURITY LABEL FOR anon ON COLUMN avis.answer IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN avis.introduction IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.body IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN dossiers.search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.private_search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN exercices.ca IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN trusted_device_tokens.token IS 'MASKED WITH VALUE NULL'",

      # champs values
      "SECURITY LABEL FOR anon ON COLUMN champs.value IS 'MASKED WITH VALUE CASE
                                                                            WHEN type = $$Champs::DossierLinkChamp$$ THEN value
                                                                            ELSE NULL
                                                                            END'",

      "SECURITY LABEL FOR anon ON COLUMN champs.value_json IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN champs.external_id IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN champs.data IS 'MASKED WITH VALUE NULL'"
    ]

    # Wrap in transaction to ensure previous rules won't be removed in case of error
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute "SELECT anon.remove_masks_for_all_columns()"

      sql_rules.each do |sql|
        ActiveRecord::Base.connection.execute sql
      rescue StandardError
        puts sql
        raise
      end
    end
  end

  desc "Seed simple data to test anonymization"
  task seed_test_data: :environment do
    fail "Bad enviroment" unless Rails.env.development?

    # Ask confirmation about truncating all data in the database. Then continue only if user types 'yes'
    puts "This task will truncate all tables, including #{User.count} users. Are you sure? (yes/no)"
    if ['yes', 'y'].exclude?(STDIN.gets.chomp)
      puts "Bye"
      exit
    end

    Rake::Task["db:truncate_all"].invoke

    require "factory_bot"
    Dir[Rails.root.join("spec/factories/*.rb")].each { require _1 }

    sa_email = FactoryBot.create(:super_admin, email: "me@superadmin.ds").email
    FactoryBot.create(:user, email: sa_email)

    # test for short email anonymization
    FactoryBot.create(:user, email: "a@hey.com")

    FactoryBot.create(:dossier, :with_populated_champs, procedure: FactoryBot.create(:procedure, :with_all_champs))
    FactoryBot.create(:avis)
    FactoryBot.create(:commentaire)
    FactoryBot.create(:dossier_transfer)
    FactoryBot.create(:email_event)
    FactoryBot.create(:etablissement)
    Etablissement.create(siret: "41816609600051", dossier: FactoryBot.create(:dossier)) # degraded mode
    FactoryBot.create(:france_connect_information)
    FactoryBot.create(:individual)
    FactoryBot.create(:traitement, dossier: FactoryBot.create(:dossier))
    FactoryBot.create(:invite)
    FactoryBot.create(:trusted_device_token)

    puts "Now, connect to db with anonymized role and execute a query verifying anonymization, for example: (update with actual credentials)"
    puts "psql -U pganonrole -h localhost -d tps_development -c 'SELECT email FROM users;'"
  end
end
