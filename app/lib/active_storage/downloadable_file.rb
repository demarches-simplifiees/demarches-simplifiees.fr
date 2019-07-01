class ActiveStorage::DownloadableFile
  def initialize(url)
    @url = url
  end

  def url
    @url
  end
end
