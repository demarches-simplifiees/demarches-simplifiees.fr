class ActiveStorage::DownloadableFile
  def self.create_list_from_dossier(dossier)
    PiecesJustificativesService.zip_entries(dossier)
  end

  private

  def using_local_backend?
    [:local, :local_test, :test].include?(Rails.application.config.active_storage.service)
  end
end
