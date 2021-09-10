class ChampFetchExternalDataJob < ApplicationJob
  def perform(champ, external_id)
    if champ.external_id == external_id && champ.data.nil?
      data = champ.fetch_external_data

      if data.present?
        champ.update!(data: data)
      end
    end
  end
end
