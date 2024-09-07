class Champs::PieceJustificativeChamp < Champ
  FILE_MAX_SIZE = 200.megabytes

  has_many_attached :piece_justificative_file

  # TODO: if: -> { validate_champ_value? || validation_context == :prefill }
  validates :piece_justificative_file,
            size: { less_than: FILE_MAX_SIZE },
            if: -> { !type_de_champ.skip_pj_validation }

  validates :piece_justificative_file,
            content_type: AUTHORIZED_CONTENT_TYPES,
            if: -> { !type_de_champ.skip_content_type_pj_validation }

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
end
