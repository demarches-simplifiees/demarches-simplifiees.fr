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
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::CheckboxChamp < Champs::BooleanChamp
  def for_export
    true? ? 'on' : 'off'
  end

  def mandatory_blank?
    mandatory? && (blank? || !true?)
  end

  # TODO remove when normalize_checkbox_values is over
  def true?
    value_with_legacy == TRUE_VALUE
  end

  private

  # TODO remove when normalize_checkbox_values is over
  def value_with_legacy
    value == 'on' ? TRUE_VALUE : value
  end
end
