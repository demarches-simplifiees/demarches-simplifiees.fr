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
class Champs::CiviliteChamp < Champ
  validates :value, inclusion: ["M.", "Mme"], allow_nil: true, allow_blank: false

  def html_label?
    false
  end

  def female_input_id
    "#{input_id}-female"
  end

  def male_input_id
    "#{input_id}-male"
  end

  def focusable_input_id
    female_input_id
  end
end
