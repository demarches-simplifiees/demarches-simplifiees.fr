class Champs::PieceJustificativeChamp < Champ
  MAX_SIZE = 200.megabytes

  ACCEPTED_FORMATS = [
    "text/plain",
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

  # TODO: once we're running on Rails 6, re-enable this validation.
  # See https://github.com/betagouv/demarches-simplifiees.fr/issues/4926
  #
  # validates :piece_justificative_file,
  #   content_type: ACCEPTED_FORMATS,
  #   size: { less_than: MAX_SIZE }

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def mandatory_and_blank?
    mandatory? && !piece_justificative_file.attached?
  end

  def for_export
    piece_justificative_file.filename.to_s if piece_justificative_file.attached?
  end

  def for_api
    if piece_justificative_file.attached? && (piece_justificative_file.virus_scanner.safe? || piece_justificative_file.virus_scanner.pending?)
      piece_justificative_file.service_url
    end
  end
end
