Flipflop.configure do
  strategy :cookie,
    secure: Rails.env.production?,
    httponly: true
  strategy :active_record
  strategy :user_preference
  strategy :default

  group :champs do
    feature :champ_siret,
      title: "Champ SIRET"
    feature :champ_integer_number,
      title: "Champ nombre entier"
    feature :champ_repetition,
      title: "Bloc répétable (NE MARCHE PAS – NE PAS ACTIVER)"
  end

  feature :web_hook
  feature :publish_draft
  feature :enable_email_login_token
  feature :new_champs_editor

  group :production do
    feature :remote_storage,
      default: ENV['FOG_ENABLED'] == 'enabled'
    feature :weekly_overview,
      default: ENV['APP_NAME'] == 'tps'
    feature :pre_maintenance_mode
    feature :maintenance_mode
  end

  if Rails.env.test?
    # It would be nicer to configure this in administrateur_spec.rb in #feature_enabled?,
    # but that results in a FrozenError: can't modify frozen Hash

    feature :test_a
    feature :test_b
  end
end
