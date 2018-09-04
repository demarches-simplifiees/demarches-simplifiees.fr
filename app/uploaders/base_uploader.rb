class BaseUploader < CarrierWave::Uploader::Base
  def cache_dir
    Rails.application.secrets.carrierwave[:cache_dir]
  end
end
