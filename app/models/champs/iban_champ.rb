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
class Champs::IbanChamp < Champ
  validates_with IbanValidator, if: -> { validation_context != :brouillon }
  after_validation :format_iban

  def for_api
    to_s.gsub(/\s+/, '')
  end

  def for_api_v2
    for_api
  end

  private

  def format_iban
    self.value = value&.gsub(/\s+/, '')&.gsub(/(.{4})/, '\0 ')
  end
end
