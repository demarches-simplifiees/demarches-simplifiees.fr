# frozen_string_literal: true

class Champs::PieceJustificativeChamp < Champ
  FILE_MAX_SIZE = 200.megabytes

  has_many_attached :piece_justificative_file

  validates :piece_justificative_file,
    size: { less_than: FILE_MAX_SIZE },
    if: -> { can_validate? && !type_de_champ.skip_pj_validation }

  validates :piece_justificative_file,
    content_type: AUTHORIZED_CONTENT_TYPES,
    if: -> { can_validate? && !type_de_champ.skip_content_type_pj_validation }

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def uses_external_data?
    RIB?
  end

  def should_ui_auto_refresh?
    RIB?
  end

  def ready_for_external_call?
    piece_justificative_file.blobs.present?
  end

  # should also define external_error_present
  # but the implem is linked to external_id which is not used here.
  # As ocr error are also store in ocr field, waiting_for_external_data? works
  def external_data_present?
    piece_justificative_file.blobs.first.ocr.present?
  end

  def fetch_external_data
    nil # the ocr information is added by the ImageProcessorJob when the blob is attached
  end

  def fetch_external_data_later
    nil # the job is already enqueued by the ImageProcessorJob when the blob is attached
  end
end
