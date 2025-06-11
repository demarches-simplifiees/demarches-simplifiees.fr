# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel, to: :type_de_champ

  before_save :clear_previous_result, if: -> { external_id_changed? }

  validates_with ReferentielChampValidator, if: :validate_champ_value?

  def fetch_external_data
    ReferentielService.new(referentiel:).call(external_id)
  end

  def update_with_external_data!(data:)
    transaction do
      update!(
        value: external_id,                # now that we have the data, we can set the value
        data:,                             # keep raw API response
        value_json: todo_map_stuff(data:), # columnize the data
        fetch_external_data_exceptions: [] # void previous errors
      )
      propagate_prefill(data)
    end
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

  def clear_previous_result
    self.value = nil
    self.data = nil
    self.value_json = nil
    self.fetch_external_data_exceptions = []
  end

  def propagate_prefill(data)
    type_de_champ.referentiel_mapping_prefillable_with_stable_id.each do |jsonpath, mapping|
      update_prefillable_champ(
        mapping[:prefill_stable_id],
        JSONPath.value(data, jsonpath)
      )
    end
  end

  def update_prefillable_champ(prefill_stable_id, value)
    prefill_champ = find_prefillable_champ(prefill_stable_id)
    prefill_champ.update(value:) if prefill_champ.present?
  end

  def find_prefillable_champ(prefill_stable_id)
    prefillable_type_de_champ = dossier.find_type_de_champ_by_stable_id(prefill_stable_id)
    dossier.champ_for_update(prefillable_type_de_champ, updated_by: :api)
  end
end
