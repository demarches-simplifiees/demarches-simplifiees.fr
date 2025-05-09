# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel, to: :type_de_champ

  validates :value, presence: true, allow_blank: true, allow_nil: true, if: -> { validate_champ_value? }
  validate :api_response_stored, if: -> { value.present? && validate_champ_value? && !fetch_external_data_pending? }
  before_save :clear_previous_result, if: -> { external_id_changed? }

  def fetch_external_data
    ReferentielService.new(referentiel:).(external_id)
  end

  def update_with_external_data!(data:)
    update!(value: external_id, data:, value_json: todo_map_stuff(data:), fetch_external_data_exceptions: [])
  end

  def todo_map_stuff(data:)
    data
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  private

  def api_response_stored
    return if data.present?

    errors.add(:value, :api_response_not_stored)
  end

  def clear_previous_result
    return if !external_id_changed?

    self.value = nil
    self.data = nil
    self.value_json = nil
    self.fetch_external_data_exceptions = []
  end
end
