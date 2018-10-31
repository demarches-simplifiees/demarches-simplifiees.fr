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
    feature :champ_linked_dropdown,
      title: "Champ double menu déroulant"
    feature :champ_carte,
      title: "Champ Carte"
    feature :champ_integer_number,
      title: "Champ nombre entier"
  end

  feature :web_hook
  feature :publish_draft
  feature :support_form

  group :production do
    feature :remote_storage,
      default: ENV['FOG_ENABLED'] == 'enabled'
    feature :weekly_overview,
      default: ENV['APP_NAME'] == 'tps'
  end

  feature :pre_maintenance_mode
  feature :maintenance_mode
end
