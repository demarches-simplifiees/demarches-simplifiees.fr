# frozen_string_literal: true

module Maintenance::Ignored
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

      value_json = champ.value_json
      return if value_json.blank?
      return if value_json['code_departement'].blank?

      external_id = APIGeoService.commune_code(value_json['code_departement'], champ.value)

      if external_id.present?
        champ.update(external_id:)
      end
    end
  end
end
