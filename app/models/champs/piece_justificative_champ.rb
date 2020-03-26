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

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def mandatory_and_blank?
    mandatory? && !piece_justificative_file.attached?
  end

  def for_api
    if piece_justificative_file.attached? && (piece_justificative_file.virus_scanner.safe? || piece_justificative_file.virus_scanner.pending?)
      piece_justificative_file.service_url
    end
  end
end
