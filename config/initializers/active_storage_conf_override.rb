# FIXME: remove this once we moved to a properly structured infrastructure
if Rails.env.production? || Rails.env.staging?
  Rails.application.config.active_storage.service = :clever_cloud
end
