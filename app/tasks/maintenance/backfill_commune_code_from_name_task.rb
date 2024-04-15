# frozen_string_literal: true

module Maintenance
  class BackfillCommuneCodeFromNameTask < MaintenanceTasks::Task
    attribute :champ_ids, :string
    validates :champ_ids, presence: true

    def collection
      Champ.where(id: champ_ids.split(',').map(&:strip).map(&:to_i))
    end

    def process(champ)
      return if champ.type != "Champs::CommuneChamp"
      return if champ.external_id.present?
      return if champ.value.blank?

      data = champ.data
      return if data.blank?
      return if data['code_departement'].blank?

      external_id = APIGeoService.commune_code(data['code_departement'], champ.value)

      if external_id.present?
        champ.update(external_id:)
      end
    end
  end
end
