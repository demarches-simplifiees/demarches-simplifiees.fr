class RemoteDownloader
  def initialize(filename)
    @filename = filename
  end

  def url
    @url ||= File.join(STORAGE_URL, @filename)
  end
end
