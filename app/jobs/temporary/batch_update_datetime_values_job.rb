class Temporary::BatchUpdateDatetimeValuesJob < ApplicationJob
  def perform(ids)
    ids.each do |id|
      datetime_champ = Champs::DatetimeChamp.find(id)
      datetime_champ.update_columns(value: DateTime.iso8601(value).to_s)
    rescue ArgumentError, Date::Error # rubocop:disable Lint/ShadowedException
      datetime_champ.update_columns(value: nil) unless datetime_champ.value.nil?
    end
  end
end
