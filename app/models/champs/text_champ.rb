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
class Champs::TextChamp < Champ
  def eval_condition(operator, value)
    case operator
    when 'is'
      for_api_v2 == value
    when 'is_not'
      for_api_v2 != value
    when 'contains'
      for_api_v2.match(value)
    when 'is_blank'
      blank?
    when 'is_not_blank'
      !blank?
    end
  end
end
