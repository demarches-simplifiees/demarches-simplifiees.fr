class RemoteDownloader
  DEST_URL = "https://storage.apientreprise.fr/" + CarrierWave::Uploader::Base.fog_directory + '/'

  def initialize(filename)
    @filename = filename
  end

  def url
    @url ||= File.join(DEST_URL, @filename)
  end
end
