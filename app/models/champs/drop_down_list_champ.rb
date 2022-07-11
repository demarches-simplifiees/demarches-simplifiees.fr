# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::DropDownListChamp < Champ
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5
  OTHER = '__other__'
  delegate :options_without_empty_value_when_mandatory, to: :type_de_champ

  def render_as_radios?
    enabled_non_empty_options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end

  def options?
    drop_down_list_options?
  end

  def options
    if drop_down_other?
      drop_down_list_options + [["Autre", OTHER]]
    else
      drop_down_list_options
    end
  end

  def selected
    other_value_present? ? OTHER : value
  end

  def disabled_options
    drop_down_list_disabled_options
  end

  def enabled_non_empty_options
    drop_down_list_enabled_non_empty_options
  end

  def other_value_present?
    drop_down_other? && value.present? && drop_down_list_options.exclude?(value)
  end

  def drop_down_other?
    drop_down_other == "1" || drop_down_other == true
  end

  def value=(value)
    if value != OTHER
      write_attribute(:value, value)
    end
  end

  def value_other=(value)
    write_attribute(:value, value)
  end

  def value_other
    other_value_present? ? value : ""
  end
end
