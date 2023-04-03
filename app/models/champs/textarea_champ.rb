# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean          default(FALSE)
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::TextareaChamp < Champs::TextChamp
  def for_export
    value.present? ? ActionView::Base.full_sanitizer.sanitize(value) : nil
  end

  def character_count(text)
    return text&.bytesize
  end

  def analyze_character_count(characters, limit)
    if characters
      threshold_75 = limit * 0.75

      if characters >= limit
        return :warning
      elsif characters >= threshold_75
        return :info
      end
    end
  end

  def remaining_characters(characters, limit)
    threshold_75 = limit * 0.75
    limit - characters if characters >= threshold_75
  end

  def excess_characters(characters, limit)
    characters - limit if characters > limit
  end
end
