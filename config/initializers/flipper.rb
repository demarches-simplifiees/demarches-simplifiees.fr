# This setup is primarily for first deployment, because consequently
# we can add new features from the Web UI. However when the new DB is created
# this will immediately migrate the default features to be controlled.
#
require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

def setup_features(features)
  features.each do |feature|
    Flipper.add(feature) unless Flipper.exist?(feature)
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
  :gallery_demande,
  :groupe_instructeur_api_hack,
  :hide_instructeur_email,
  :qrcoded_pdf,
  :sva,
  :switch_domain,
  :visa,
  :champ_update_by_stable_id
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

Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ActiveSupportCacheStore.new(
      Flipper::Adapters::ActiveRecord.new,
      ActiveSupport::Cache::MemoryStore.new,
      expires_in: 10.seconds
    )
  end
end

Rails.application.configure do
  # don't preload features for /assets/* but do for everything else
  config.flipper.preload = -> (request) { !request.path.start_with?('/assets/', '/ping') }
  config.flipper.strict = Rails.env.development?
end
