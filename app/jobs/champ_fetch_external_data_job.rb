class ChampFetchExternalDataJob < ApplicationJob
  def perform(champ)
    if champ.external_id.present?
      data = champ.fetch_external_data

      if data.present?
        champ.update!(data: data)
      end
    end
  end
end
