class Temporary::BatchUpdateDatetimeValuesJob < ApplicationJob
  def perform(ids)
    ids.each do |id|
      datetime_champ = Champs::DatetimeChamp.find(id)
      current_value_in_time = Time.zone.parse(datetime_champ.value)

      if current_value_in_time.present?
        datetime_champ.update_columns(value: current_value_in_time.iso8601)
      else
        update_value_to_nil_if_possible(datetime_champ)
      end

    rescue TypeError
      update_value_to_nil_if_possible(datetime_champ)
    end
  end

  private

  def update_value_to_nil_if_possible(datetime_champ)
    return if datetime_champ.value.nil?

    datetime_champ.update_columns(value: nil) unless datetime_champ.required?
  end
end
