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
  end

  feature :web_hook

  group :production do
    feature :remote_storage,
      default: Rails.env.production? || Rails.env.staging?
    feature :weekly_overview,
      default: Rails.env.production?
  end

  feature :pre_maintenance_mode
  feature :maintenance_mode
end
