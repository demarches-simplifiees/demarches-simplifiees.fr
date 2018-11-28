class BaseUploader < CarrierWave::Uploader::Base
  def cache_dir
    Rails.application.secrets.carrierwave[:cache_dir]
  end

  # https://github.com/carrierwaveuploader/carrierwave/wiki/how-to:-silently-ignore-missing-files-on-destroy-or-overwrite
  def remove!
    begin
      super
    rescue Fog::OpenStack::Storage::NotFound
    end
  end
end
