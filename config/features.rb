Flipflop.configure do
  strategy :cookie
  strategy :active_record
  strategy :user_preference
  strategy :default

  group :champs do
    feature :champ_pj
    feature :champ_siret
  end
  feature :web_hook
  group :production do
    feature :remote_storage,
      default: Rails.env.production? || Rails.env.staging?
    feature :weekly_overview,
      default: Rails.env.production?
  end
end
