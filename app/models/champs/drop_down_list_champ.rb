# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
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

  def render_as_radios?
    enabled_non_empty_options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end

  def options?
    drop_down_list_options?
  end

  def options
    drop_down_list_options.filter { |option| option.casecmp('autre') != 0 } | [value]
  end

  def disabled_options
    drop_down_list_disabled_options
  end

  def enabled_non_empty_options
    drop_down_list_enabled_non_empty_options
  end

  def allows_other_value?
    drop_down_list_options.find { |option| option.casecmp('autre') == 0 }
  end
end
