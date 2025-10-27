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

  private

  def fetch_external_data_later
    nil # the job is already enqueued by the ImageProcessorJob when the blob is attached
  end

  # store directly the data in value_json
  # as there is no transformation to do
  def update_external_data!(data:)
    update!(value_json: data, fetch_external_data_exceptions: [])
  end

  def cleanup_if_empty
    if uses_external_data? && persisted? &&
       (external_identifier_changed? || !piece_justificative_file.attached?)
      self.value_json = nil
      self.fetch_external_data_exceptions = []
    end
  end

  def external_data_present?
    value_json.present?
  end

  # Does not detect file removal
  def external_identifier_changed?
    piece_justificative_file.attached? && piece_justificative_file.blobs.first.changed?
  end

  def ready_for_external_call?
    piece_justificative_file.blobs.present?
  end

  def fetch_external_data
    blob = piece_justificative_file.blobs.first
    OCRService.analyze(blob)
  end
end
