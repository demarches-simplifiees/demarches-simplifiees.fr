class RemoteDownloader
  def initialize(filename)
    @filename = filename
  end

  def url
    @url ||= File.join(base_url, CarrierWave::Uploader::Base.fog_directory, @filename)
  end

  protected

  def base_url
    Rails.application.secrets.fog[:base_url]
  end
end
