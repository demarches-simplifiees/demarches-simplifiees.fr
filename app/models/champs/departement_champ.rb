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
class Champs::DepartementChamp < Champs::TextChamp
  def for_export
    [name, code]
  end

  def to_s
    formatted_value
  end

  def for_tag
    formatted_value
  end

  def for_api
    formatted_value
  end

  def for_api_v2
    formatted_value.tr('–', '-')
  end

  def selected
    code
  end

  def code
    external_id || APIGeoService.departement_code(name)
  end

  def name
    maybe_code_and_name = value&.match(/^(\w{2,3}) - (.+)/)
    if maybe_code_and_name
      maybe_code_and_name[2]
    else
      value
    end
  end

  def value=(code)
    if [2, 3].include?(code&.size)
      self.external_id = code
      super(APIGeoService.departement_name(code))
    elsif code.blank?
      self.external_id = nil
      super(nil)
    end
  end

  private

  def formatted_value
    blank? ? "" : "#{code} – #{name}"
  end
end
