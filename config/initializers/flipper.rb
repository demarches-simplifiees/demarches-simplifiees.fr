# This setup is primarily for first deployment, because consequently
# we can add new features from the Web UI. However when the new DB is created
# this will immediately migrate the default features to be controlled.
def setup_features(features)
  existing = Flipper.preload(features).map { _1.name.to_sym }
  missing = features - existing

  missing.each do |feature|
    # Feature is disabled by default
    Flipper.add(feature.to_s)
  end
end

# A list of features to be deployed on first push
features = [
  :administrateur_web_hook,
  :api_particulier,
  :attestation_v2,
  :blocking_pending_correction,
  :cojo_type_de_champ,
  :dossier_pdf_vide,
  :engagement_juridique_type_de_champ,
  :export_order_by_revision,
  :expression_reguliere_type_de_champ,
  :groupe_instructeur_api_hack,
  :hide_instructeur_email,
  :sva,
  :switch_domain
]

def database_exists?
  ActiveRecord::Base.connection
  true
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError, PG::ConnectionBad
  false
end

ActiveSupport.on_load(:active_record) do
  if database_exists? && ActiveRecord::Base.connection.data_source_exists?('flipper_features')
    setup_features(features)
  end
end

Rails.application.configure do
  config.flipper.strict = Rails.env.development?
end
