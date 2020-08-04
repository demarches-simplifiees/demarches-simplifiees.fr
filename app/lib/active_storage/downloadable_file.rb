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
    pjs = PiecesJustificativesService.liste_pieces_justificatives(dossier)
    pjs.map do |piece_justificative|
      [
        piece_justificative,
        self.timestamped_filename(piece_justificative)
      ]
    end
  end

  private

  def self.timestamped_filename(piece_justificative)
    # we pad the original file name with a timestamp
    # and a short id in order to help identify multiple versions and avoid name collisions
    extension = File.extname(piece_justificative.filename.to_s)
    basename = File.basename(piece_justificative.filename.to_s, extension)
    timestamp = piece_justificative.created_at.strftime("%d-%m-%Y-%H-%M")
    id = piece_justificative.id % 10000

    "#{basename}-#{timestamp}-#{id}#{extension}"
  end

  def using_local_backend?
    [:local, :local_test, :test].include?(Rails.application.config.active_storage.service)
  end
end
