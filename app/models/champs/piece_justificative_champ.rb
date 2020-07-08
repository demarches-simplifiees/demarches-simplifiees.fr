# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  parent_id        :bigint
#  type_de_champ_id :integer
#
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

  validates :piece_justificative_file,
    content_type: ACCEPTED_FORMATS,
    size: { less_than: MAX_SIZE }

  before_save :update_skip_pj_validation

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

  def piece_justificative_file_errors
    errors = []

    if piece_justificative_file.attached? && piece_justificative_file.previous_changes.present?
      if piece_justificative_file.blob.byte_size > MAX_SIZE
        errors << "Le fichier #{piece_justificative_file.filename} est trop lourd, il doit faire au plus #{MAX_SIZE.to_s(:human_size, precision: 2)}"
      end

      if !piece_justificative_file.blob.content_type.in?(ACCEPTED_FORMATS)
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
      piece_justificative_file.service_url
    end
  end

  def update_skip_pj_validation
    type_de_champ.update(skip_pj_validation: true)
  end
end
