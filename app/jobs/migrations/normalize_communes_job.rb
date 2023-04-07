class Migrations::NormalizeCommunesJob < ApplicationJob
  def perform(ids)
    Champs::CommuneChamp.where(id: ids).find_each do |champ|
      next if champ.external_id.blank?

      value_json = champ.value_json || {}

      if !champ.departement?
        metro_code = champ.external_id[0..1]
        drom_com_code = champ.external_id[0..2]

        if metro_code == '97' || metro_code == '98'
          value_json[:code_departement] = drom_com_code
        else
          value_json[:code_departement] = metro_code
        end
      end

      if !champ.code_postal? && champ.code_postal_with_fallback?
        value_json[:code_postal] = champ.code_postal_with_fallback
      end

      if value_json.present?
        champ.update_column(:value_json, value_json)
      end
    end
  end
end
