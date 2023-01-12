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
class Champs::IntegerNumberChamp < Champ
  validates :value, numericality: {
    only_integer: true,
    allow_nil: true,
    allow_blank: true,
    message: -> (object, _data) {
      # i18n-tasks-use t('errors.messages.not_an_integer')
      "« #{object.libelle} » " + object.errors.generate_message(:value, :not_an_integer)
    }
  }

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
