Flipflop.configure do
  strategy :cookie,
    secure: Rails.env.production?,
    httponly: true
  strategy :active_record
  strategy :user_preference
  strategy :default

  group :champs do
    feature :champ_pj,
      title: "Champ pièce justificative"
    feature :champ_siret,
      title: "Champ SIRET"
    feature :champ_integer_number,
      title: "Champ nombre entier"
    feature :champ_repetition,
      title: "Bloc répétable (NE MARCHE PAS – NE PAS ACTIVER)"
  end

  feature :web_hook
  feature :publish_draft
  feature :support_form
  feature :enable_email_login_token

  group :production do
    feature :remote_storage,
      default: ENV['FOG_ENABLED'] == 'enabled'
    feature :weekly_overview,
      default: ENV['APP_NAME'] == 'tps'
    feature :pre_maintenance_mode
    feature :maintenance_mode
  end
end
