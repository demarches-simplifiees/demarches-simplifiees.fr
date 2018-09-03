class RemoteDownloader
  def initialize(filename)
    @filename = filename
  end

  def url
    @url ||= File.join(base_url, CarrierWave::Uploader::Base.fog_directory, @filename)
  end

  protected

  def base_url
    FOG_BASE_URL
  end
end
