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

  validate :validate_dynamic_piece_justificative_rules,
    if: -> { can_validate? && piece_justificative_file.attached? }

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def fetch_external_data_later
    nil # the job is already enqueued by the ImageProcessorJob when the blob is attached
  end

  def external_error_present?
    fetch_external_data_exceptions.present? && piece_justificative_file.attached?
  end

  def uses_external_data?
    RIB?
  end

  private

  def should_ui_auto_refresh?
    RIB?
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

  def validate_dynamic_piece_justificative_rules
    allowed_types = nil
    max_size = nil

    if type_de_champ.titre_identite_nature?
      allowed_types = type_de_champ.allowed_content_types
      max_size = type_de_champ.max_file_size_bytes
    elsif type_de_champ.rib_nature?
      allowed_types = type_de_champ.allowed_content_types
    elsif type_de_champ.pj_limit_formats? && type_de_champ.pj_format_families.present?
      allowed_types = type_de_champ.allowed_content_types
    end

    return if allowed_types.nil? && max_size.nil?

    piece_justificative_file.blobs.each do |blob|
      if allowed_types.present? && !allowed_types.include?(blob.content_type)
        errors.add(:piece_justificative_file, :content_type_invalid)
      end

      if max_size.present? && blob.byte_size > max_size
        errors.add(:piece_justificative_file, :file_size_out_of_range, max_size: ActiveSupport::NumberHelper.number_to_human_size(max_size))
      end
    end
  end
end
