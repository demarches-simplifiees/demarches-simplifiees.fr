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
class Champs::DecimalNumberChamp < Champ
  validates :value, numericality: {
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      "« #{object.libelle} » " + object.errors.generate_message(:value, :not_a_number)
    }
  }

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  def eval_condition(operator, value)
    case operator
    when 'is'
      for_condition == value.to_f
    when 'is_not'
      for_condition != value.to_f
    when 'gt'
      for_condition > value.to_f
    when 'gte'
      for_condition >= value.to_f
    when 'lt'
      for_condition < value.to_f
    when 'lte'
      for_condition <= value.to_f
    end
  end

  private

  def for_condition
    processed_value || 0
  end

  def processed_value
    value&.to_f
  end
end
