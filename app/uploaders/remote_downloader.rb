class RemoteDownloader
  def initialize(filename)
    @filename = filename
  end

  def url
    if @filename.present?
      @url ||= File.join(base_url, CarrierWave::Uploader::Base.fog_directory, @filename)
    end
  end

  protected

  def base_url
    FOG_BASE_URL
  end
end
