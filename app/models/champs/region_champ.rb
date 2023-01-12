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
class Champs::RegionChamp < Champs::TextChamp
  def for_export
    [name, code]
  end

  def selected
    code
  end

  def name
    value
  end

  def code
    external_id || APIGeoService.region_code(value)
  end

  def value=(code)
    if code&.size == 2
      self.external_id = code
      super(APIGeoService.region_name(code))
    elsif code.blank?
      self.external_id = nil
      super(nil)
    end
  end
end
