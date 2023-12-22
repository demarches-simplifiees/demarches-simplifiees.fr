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
class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true
  }
  validate :min_max_validation

  def min_max_validation
    return if value.blank?

    if type_de_champ.min.present? && value.to_i < type_de_champ.min.to_i
      errors.add(:value, :greater_than_or_equal_to, value: value, count: type_de_champ.min.to_i)
    end
    if type_de_champ.max.present? && value.to_i > type_de_champ.max.to_i
      errors.add(:value, :less_than_or_equal_to, value: value, count: type_de_champ.max.to_i)
    end
  end

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def processed_value
    value&.to_i
  end
end
