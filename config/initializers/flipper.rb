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
  :api_particulier,
  :dossier_pdf_vide,
  :hide_instructeur_email,
  :qrcoded_pdf,
  :visa,
  :attestation_v2,
  :procedure_routage_api,
  :groupe_instructeur_api_hack,
  :rerouting
]

def database_exists?
  ActiveRecord::Base.connection
  true
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished
  false
end

ActiveSupport.on_load(:active_record) do
  if database_exists? && ActiveRecord::Base.connection.data_source_exists?('flipper_features')
    setup_features(features)
  end
end
