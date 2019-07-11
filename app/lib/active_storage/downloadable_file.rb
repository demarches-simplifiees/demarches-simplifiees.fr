class ActiveStorage::DownloadableFile
  def initialize(attached)
    if using_local_backend?
      @url = 'file://' + ActiveStorage::Blob.service.path_for(attached.key)
    else
      @url = attached.service_url
    end
  end

  def url
    @url
  end

  private

  def using_local_backend?
    [:local, :local_test].include?(Rails.application.config.active_storage.service)
  end
end
