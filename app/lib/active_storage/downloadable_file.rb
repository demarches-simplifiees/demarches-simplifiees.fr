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

  def self.create_list_from_dossier(dossier)
    PiecesJustificativesService.zip_entries(dossier)
  end

  private

  def using_local_backend?
    [:local, :local_test, :test].include?(Rails.application.config.active_storage.service)
  end
end
