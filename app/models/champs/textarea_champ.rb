# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean
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

  def remaining_characters
    character_limit_base - character_count if character_count >= character_limit_threshold_75
  end

  def excess_characters
    character_count - character_limit_base if character_count > character_limit_base
  end

  def character_limit_info?
    analyze_character_count == :info
  end

  def character_limit_warning?
    analyze_character_count == :warning
  end

  private

  def character_count
    return value&.bytesize
  end

  def character_limit_base
    character_limit&.to_i
  end

  def character_limit_threshold_75
    character_limit_base * 0.75
  end

  def analyze_character_count
    if character_limit? && character_count.present?
      if character_count >= character_limit_base
        return :warning
      elsif character_count >= character_limit_threshold_75
        return :info
      end
    end
  end
end
