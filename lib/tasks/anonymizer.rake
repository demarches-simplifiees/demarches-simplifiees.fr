namespace :anonymizer do
  desc "Inject pg_anonymizer dynamic rules. Rules can evolve over time so this tas is idempotent."
  task setup_rules: :environment do
    super_admin_emails = SuperAdmin.pluck(:email)

    sql_rules = [
      # fake emails
      "SECURITY LABEL FOR anon ON COLUMN avis.email IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.email IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN dossier_transfers.email IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN invites.email_sender IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN traitements.instructeur_email IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN users.unconfirmed_email IS 'MASKED WITH FUNCTION anon.fake_email()'",

      # users: fake emails except for super admins accounts
      "SECURITY LABEL FOR anon ON COLUMN users.email IS 'MASKED WITH VALUE CASE
                                                                           WHEN email IN (#{super_admin_emails.map { "$$#{_1}$$" }.join(',')}) THEN email
                                                                           ELSE anon.fake_email()
                                                                           END'",

      # partial emails
      "SECURITY LABEL FOR anon ON COLUMN email_events.to IS 'MASKED WITH VALUE anon.partial_email(email_events.to)'",

      # personal data
      "SECURITY LABEL FOR anon ON COLUMN individuals.nom IS 'MASKED WITH VALUE anon.fake_last_name()'",
      "SECURITY LABEL FOR anon ON COLUMN individuals.prenom IS 'MASKED WITH VALUE anon.fake_first_name()'",

      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.email_france_connect IS 'MASKED WITH VALUE anon.fake_email()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.family_name IS 'MASKED WITH VALUE anon.fake_last_name()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.france_connect_particulier_id IS 'MASKED WITH VALUE anon.random_string(2)'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.given_name IS 'MASKED WITH VALUE anon.fake_first_name()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.birthplace IS 'MASKED WITH VALUE anon.fake_city()'",
      "SECURITY LABEL FOR anon ON COLUMN france_connect_informations.merge_token IS 'MASKED WITH VALUE anon.random_string(2)'",

      # various data
      "SECURITY LABEL FOR anon ON COLUMN active_storage_blobs.key IS 'MASKED WITH VALUE $$REDACTED$$'",
      "SECURITY LABEL FOR anon ON COLUMN api_tokens.encrypted_token IS 'MASKED WITH VALUE anon.random_string(5)'",
      "SECURITY LABEL FOR anon ON COLUMN avis.answer IS 'MASKED WITH VALUE anon.random_string(2)'",
      "SECURITY LABEL FOR anon ON COLUMN avis.introduction IS 'MASKED WITH VALUE anon.random_string(2)'",
      "SECURITY LABEL FOR anon ON COLUMN commentaires.body IS 'MASKED WITH VALUE anon.random_string(2)'",
      "SECURITY LABEL FOR anon ON COLUMN dossiers.search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon on COLUMN dossiers.private_search_terms IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN exercices.ca IS 'MASKED WITH VALUE NULL'",
      "SECURITY LABEL FOR anon ON COLUMN trusted_device_tokens.token IS 'MASKED WITH VALUE NULL'",

      # champs values
      "SECURITY LABEL FOR anon ON COLUMN champs.value IS 'MASKED WITH VALUE NULL'",
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
end
