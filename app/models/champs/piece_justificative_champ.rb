class Champs::PieceJustificativeChamp < Champ
  PIECE_JUSTIFICATIVE_FILE_MAX_SIZE = 200.megabytes

  PIECE_JUSTIFICATIVE_FILE_ACCEPTED_FORMATS = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.oasis.opendocument.text",
    "application/vnd.oasis.opendocument.presentation",
    "application/vnd.oasis.opendocument.spreadsheet",
    "image/png",
    "image/jpeg"
  ]

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def mandatory_and_blank?
    mandatory? && !piece_justificative_file.attached?
  end

  def piece_justificative_file_errors
    errors = []

    if piece_justificative_file.attached? && piece_justificative_file.previous_changes.present?
      if piece_justificative_file.blob.byte_size > PIECE_JUSTIFICATIVE_FILE_MAX_SIZE
        errors << "Le fichier #{piece_justificative_file.filename} est trop lourd, il doit faire au plus #{PIECE_JUSTIFICATIVE_FILE_MAX_SIZE.to_s(:human_size, precision: 2)}"
      end

      if !piece_justificative_file.blob.content_type.in?(PIECE_JUSTIFICATIVE_FILE_ACCEPTED_FORMATS)
        errors << "Le fichier #{piece_justificative_file.filename} est dans un format que nous n'acceptons pas"
      end

      # FIXME: add Clamav check
    end

    if errors.present?
      piece_justificative_file.purge_later
    end

    errors
  end

  def for_api
    if piece_justificative_file.attached? && (piece_justificative_file.virus_scanner.safe? || piece_justificative_file.virus_scanner.pending?)
      Rails.application.routes.url_helpers.url_for(piece_justificative_file)
    end
  end
end
