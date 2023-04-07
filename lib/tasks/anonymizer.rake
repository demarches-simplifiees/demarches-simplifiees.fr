namespace :anonymizer do
  # When you created table or columns, you must anonymize them by updating anonymization rules below if necessary.
  # Then update this version number to match the version defined in db/schema.rb.
  ANONYMIZER_VERSION = 2023_03_31_075755

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
      # partial emails
      "SECURITY LABEL FOR anon ON COLUMN avis.email IS 'MASKED WITH FUNCTION anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.email IS 'MASKED WITH FUNCTION anon.partial_email(email)'",
      "SECURITY LABEL FOR anon ON COLUMN dossier_transfers.email IS 'MASKED WITH FUNCTION anon.partial_email(email)'",
      "SECURITY LABEL FOR anon on COLUMN dossier_transfer_logs.from IS 'MASKED WITH FUNCTION anon.partial_email(dossier_transfer_logs.from)'",
      "SECURITY LABEL FOR anon on COLUMN dossier_transfer_logs.to IS 'MASKED WITH FUNCTION anon.partial_email(dossier_transfer_logs.to)'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.archived_by IS 'MASKED WITH VALUE CASE
                                                                              WHEN archived_by IS NULL THEN NULL
                                                                              ELSE anon.partial_email(archived_by)
                                                                              END'",
      "SECURITY LABEL FOR anon ON COLUMN email_events.to IS 'MASKED WITH FUNCTION anon.partial_email(email_events.to)'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.email_france_connect IS 'MASKED WITH FUNCTION anon.partial_email(email_france_connect)'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email IS 'MASKED WITH VALUE CONCAT(id, $$+$$, anon.partial_email(email))'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email_sender IS 'MASKED WITH FUNCTION anon.partial_email(email_sender)'",
      "SECURITY LABEL FOR anon on COLUMN merge_logs.from_user_email IS 'MASKED WITH FUNCTION anon.partial_email(from_user_email)'",
      "SECURITY LABEL FOR anon ON COLUMN traitements.instructeur_email IS 'MASKED WITH FUNCTION anon.partial_email(instructeur_email)'",
      "SECURITY LABEL FOR anon ON COLUMN users.unconfirmed_email IS 'MASKED WITH FUNCTION anon.partial_email(unconfirmed_email)'",

      # users: partial emails except for super admins accounts, but ensure unicity
      "SECURITY LABEL FOR anon ON COLUMN users.email IS 'MASKED WITH VALUE CASE
                                                                           WHEN email IN (#{super_admin_emails.map { "$$#{_1}$$" }.join(',')}) THEN email
                                                                           ELSE CONCAT(id, $$+$$, anon.partial_email(email))
                                                                           END'",

      # other personal data
      "SECURITY LABEL FOR anon ON COLUMN individuals.birthdate IS 'MASKED WITH VALUE CASE
                                                                                     WHEN birthdate IS NULL THEN NULL
                                                                                     ELSE LOWER(anon.generalize_daterange(birthdate, $$decade$$))
                                                                                     END'",
      "SECURITY LABEL FOR anon ON COLUMN individuals.nom IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN individuals.prenom IS 'MASKED WITH VALUE $$REDACTED$$'",

      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.birthdate IS 'MASKED WITH VALUE CASE
                                                                                                     WHEN birthdate IS NULL THEN NULL
                                                                                                     ELSE LOWER(anon.generalize_daterange(birthdate, $$decade$$))
                                                                                                     END'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.birthplace IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.family_name IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.france_connect_particulier_id IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.given_name IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.merge_token IS 'MASKED WITH FUNCTION $$REDACTED$$'",

      "SECURITY LABEL FOR anon ON COLUMN super_admins.current_sign_in_ip IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.last_sign_in_ip IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.encrypted_otp_secret IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.encrypted_otp_secret_iv IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.encrypted_otp_secret_salt IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.encrypted_password IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.reset_password_token IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN super_admins.unlock_token IS 'MASKED WITH VALUE NULL'",

      "SECURITY LABEL FOR anon ON COLUMN users.current_sign_in_ip IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN users.last_sign_in_ip IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN users.confirmation_token IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN users.encrypted_password IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN users.reset_password_token IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN users.unlock_token IS 'MASKED WITH VALUE NULL'",

      # delayed jobs may contain sensitive data
      "SECURITY LABEL FOR anon ON COLUMN delayed_jobs.handler IS 'MASKED WITH VALUE $$$$'",

      # etablissement - nullify everything, random siret and address with respect of degraded mode
      "SECURITY LABEL FOR anon ON COLUMN etablissements.siret IS 'MASKED WITH VALUE REPLACE(anon.fake_siret(), $$ $$, $$$$)'",
      "SECURITY LABEL FOR anon ON COLUMN etablissements.adresse IS 'MASKED WITH VALUE CASE
                                                                                      WHEN adresse IS NULL THEN NULL
                                                                                      ELSE $$REDACTED$$
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
      "SECURITY LABEL FOR anon ON COLUMN active_storage_blobs.key IS 'MASKED WITH VALUE CONCAT(id, $$+REDACTED$$)'",
      "SECURITY LABEL FOR anon ON COLUMN api_tokens.encrypted_token IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN avis.answer IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN avis.introduction IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN avis.question_label IS 'MASKED WITH VALUE CASE
                                                                                   WHEN question_label IS NULL THEN NULL
                                                                                   ELSE $$REDACTED$$
                                                                                   END'",
      "SECURITY LABEL FOR anon ON COLUMN bulk_messages.body IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.body IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN dossiers.search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.private_search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.motivation IS 'MASKED WITH VALUE CASE
                                                                                   WHEN motivation IS NULL THEN NULL
                                                                                   ELSE $$REDACTED$$
                                                                                   END'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.prefill_token IS 'MASKED WITH VALUE CASE
                                                                                      WHEN prefill_token IS NULL THEN NULL
                                                                                      ELSE CONCAT(id, $$+REDACTED$$)
                                                                                      END'",

      "SECURITY LABEL FOR anon ON COLUMN email_events.subject IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN exercices.ca IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN geo_areas.properties IS 'MASKED WITH VALUE CASE
                                                                                    WHEN properties IS NULL THEN NULL
                                                                                    WHEN properties = $${}$$ THEN $${}$$
                                                                                    ELSE jsonb_build_object($$redacted$$, true)
                                                                                    END'",
      "SECURITY LABEL FOR anon ON COLUMN instructeurs.agent_connect_id IS 'MASKED WITH VALUE CASE
                                                                           WHEN agent_connect_id IS NULL THEN NULL
                                                                           ELSE $$REDACTED$$
                                                                           END'",
      "SECURITY LABEL FOR anon ON COLUMN instructeurs.encrypted_login_token IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN invites.message IS 'MASKED WITH VALUE CASE
                                                                               WHEN message IS NULL THEN NULL
                                                                               ELSE $$REDACTED$$
                                                                               END'",

      "SECURITY LABEL FOR anon ON COLUMN procedure_presentations.filters IS 'MASKED WITH VALUE $${}$$'",
      "SECURITY LABEL FOR anon ON COLUMN procedures.lien_dpo IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN procedures.api_entreprise_token IS 'MASKED WITH VALUE CASE
                                                                                               WHEN api_entreprise_token IS NULL THEN NULL
                                                                                               ELSE $$REDACTED$$
                                                                                               END'",
      "SECURITY LABEL FOR anon ON COLUMN procedures.encrypted_api_particulier_token IS 'MASKED WITH VALUE CASE
                                                                                                          WHEN encrypted_api_particulier_token IS NULL THEN NULL
                                                                                                          ELSE $$REDACTED$$
                                                                                                          END'",
      "SECURITY LABEL FOR anon ON COLUMN trusted_device_tokens.token IS 'MASKED WITH VALUE $$REDACTED$$'",

      "SECURITY LABEL FOR anon on COLUMN traitements.motivation IS 'MASKED WITH VALUE CASE
                                                                                      WHEN motivation IS NULL THEN NULL
                                                                                      ELSE $$REDACTED$$
                                                                                      END'",

      "SECURITY LABEL FOR anon ON COLUMN virus_scans.blob_key IS 'MASKED WITH VALUE $$REDACTED$$'",

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

    user_attributes = {
      current_sign_in_ip: "1.1.1.1", last_sign_in_ip: "1.1.1.1",
      reset_password_token: "token", unlock_token: "token"
    }
    FactoryBot.create(:user, user_attributes.merge(confirmation_token: "token"))
    FactoryBot.create(:super_admin, user_attributes.merge(encrypted_otp_secret: "token",
                                                          encrypted_otp_secret_salt: "token",
                                                          encrypted_otp_secret_iv: "token"))

    FactoryBot.create(:avis, :with_answer, question_label: "could be sensitive")
    FactoryBot.create(:commentaire, email: "commentator@email.com")

    FactoryBot.create(:dossier, :with_populated_champs, procedure: FactoryBot.create(:procedure, :with_all_champs))
    FactoryBot.create(:dossier, archived_by: "archiver@email.com", prefill_token: "token", motivation: "could be sensitive")
    FactoryBot.create(:dossier_transfer)
    DossierTransferLog.create!(dossier: FactoryBot.create(:dossier), from: "originator@email.com", to: "recipient@email.com")

    FactoryBot.create(:email_event)
    FactoryBot.create(:etablissement)
    Etablissement.create(siret: "41816609600051", dossier: FactoryBot.create(:dossier)) # degraded mode
    FactoryBot.create(:france_connect_information)
    FactoryBot.create(:geo_area, properties: {})
    FactoryBot.create(:geo_area, properties: { "something" => "to hide" })
    FactoryBot.create(:individual)
    FactoryBot.create(:instructeur, agent_connect_id: "should-be-masked")
    FactoryBot.create(:invite, message: "could be sensitive")

    random_jwt_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
    FactoryBot.create(:procedure, api_entreprise_token: random_jwt_token, api_particulier_token: random_jwt_token[..15])
    # FactoryBot.create(:procedure_presentation, filters: { "something" => "to hide" }) # factory is broken
    FactoryBot.create(:traitement, instructeur_email: "instructeur@email.com", motivation: "could be sensitive", dossier: FactoryBot.create(:dossier))
    FactoryBot.create(:trusted_device_token)

    puts "Now, connect to db with anonymized role and execute a query verifying anonymization, for example: (update with actual credentials)"
    puts "psql -U pganonrole -h localhost -d tps_development -c 'SELECT email FROM users;'"
  end

  desc "Check version consistency with schema version when new migrations are added"
  task :lint do
    changes_cmd = "git diff -G 'add_column|rename_column|create_table' origin/main -- db/migrate || echo 'error'"

    puts "Running: #{changes_cmd}"
    changes = `#{changes_cmd}`

    if changes.empty? # no schema change
      puts "No additive migration changes detected."
      next
    elsif changes.strip == "error"
      exit 1
    end

    schema_version = File.read("db/schema.rb").match(/ActiveRecord::Schema\[7\.\d\].define\(version: ([0-9_]+)\)/)[1]
    if schema_version.to_i == ANONYMIZER_VERSION
      puts "Anonymizer version matches Schema version: #{schema_version}"
      next
    end

    schema_format = "%Y_%m_%d_%H%M%S"
    anonymizer_version_formatted = Time.parse(ANONYMIZER_VERSION.to_s).utc.strftime(schema_format) # rubocop:disable Rails/TimeZone

    puts "You created table or columns but Anonymizer version does not match Schema version:"
    puts "        SCHEMA_VERSION = #{schema_version} (config/schema.rb)"
    puts "    ANONYMIZER_VERSION = #{anonymizer_version_formatted} (lib/tasks/anonymizer.rake)"
    puts "Open lib/tasks/anonymizer.rake, update anonymization rules if necessary and ANONYMIZER_VERSION to match the Schema version."

    exit 1
  end
end
