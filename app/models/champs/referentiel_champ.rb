# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel, to: :type_de_champ

  validates :value, presence: true, allow_blank: true, allow_nil: true, if: -> { api? && validate_champ_value? }
  validate :api_response_stored, if: -> { value.present? && api? && validate_champ_value? }

  def value
    external_id
  end

  def fetch_external_data
    ReferentielService.new(referentiel:).(external_id)
  end

  def update_with_external_data!(data:)
    update!(data:, value_json: todo_map_stuff(data:))
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

  def api?
    type_de_champ.api?
  end

  def api_response_stored
    return if data.present?

    errors.add(:value, :api_response_not_stored)
  end
end
