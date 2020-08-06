# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  parent_id        :bigint
#  type_de_champ_id :integer
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
    drop_down_list_options
  end

  def disabled_options
    drop_down_list_disabled_options
  end

  def enabled_non_empty_options
    drop_down_list_enabled_non_empty_options
  end
end
