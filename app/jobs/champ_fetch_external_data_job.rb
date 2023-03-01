class ChampFetchExternalDataJob < ApplicationJob
  def perform(champ, external_id)
    return if champ.external_id != external_id
    return if champ.data.present?
    return if (data = champ.fetch_external_data).blank?

    champ.update_with_external_data!(data: data)
  end
end
