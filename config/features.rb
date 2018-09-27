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
  end

  feature :web_hook
  feature :publish_draft
  feature :support_form

  feature :new_dossier_details,
    title: "Nouvelle page « Dossier »",
    default: true

  group :production do
    feature :remote_storage,
      default: ENV['FOG_ENABLED'] == 'enabled'
    feature :weekly_overview,
      default: ENV['APP_NAME'] == 'tps'
  end

  feature :pre_maintenance_mode
  feature :maintenance_mode
end
