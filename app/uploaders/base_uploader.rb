class BaseUploader < CarrierWave::Uploader::Base
  def cache_dir
    if Rails.env.production?
      '/tmp/tps-cache'
    else
      '/tmp/tps-dev-cache'
    end
  end
end
