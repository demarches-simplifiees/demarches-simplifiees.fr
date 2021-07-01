Flipper.configure do |config|
  config.default do
    Flipper.new(Flipper::Adapters::ActiveRecord.new)
  end
end

Flipper.register('Administrateurs') do |user|
  user.administrateur_id.present?
end
Flipper.register('Instructeurs') do |user|
  user.instructeur_id.present?
end

# This setup is primarily for first deployment, because consequently
# we can add new features from the Web UI. However when the new DB is created
# this will immediately migrate the default features to be controlled.
def setup_features(features)
  features.each do |feature|
    if !Flipper.exist?(feature)
      # Disable feature by default
      Flipper.disable(feature)
    end
  end
end

# A list of features to be deployed on first push
features = [
  :administrateur_web_hook,
  :down_time,
  :insee_api_v3,
  :instructeur_bypass_email_login_token,
  :maintenance_mode,
  :mini_profiler,
  :xray,
  :carte_ign,
  :localization,
  :new_look_banner
]

def database_exists?
  ActiveRecord::Base.connection
  true
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
  false
end

ActiveSupport.on_load(:active_record) do
  if database_exists? && ActiveRecord::Base.connection.data_source_exists?('flipper_features')
    setup_features(features)
  end
end
