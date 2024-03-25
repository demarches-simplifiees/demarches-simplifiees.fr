class Champs::TitreIdentiteChamp < Champ
  FILE_MAX_SIZE = 20.megabytes
  ACCEPTED_FORMATS = ['image/png', 'image/jpeg']
  validates :piece_justificative_file, content_type: ACCEPTED_FORMATS, size: { less_than: FILE_MAX_SIZE }

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def mandatory_blank?
    mandatory? && !piece_justificative_file.attached?
  end

  def blank?
    piece_justificative_file.blank?
  end

  def for_export
    piece_justificative_file.attached? ? "présent" : "absent"
  end

  def allow_multiple_attachments?
    false
  end

  def for_api
    nil
  end
end
