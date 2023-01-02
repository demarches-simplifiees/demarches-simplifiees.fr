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
#  type_de_champ_id               :integer
#
class Champs::PaysChamp < Champs::TextChamp
  validates :value, inclusion: APIGeoService.countries.pluck(:name), allow_nil: true, allow_blank: false
  validates :external_id, inclusion: APIGeoService.countries.pluck(:code), allow_nil: true, allow_blank: false

  def for_export
    [name, code]
  end

  def to_s
    name
  end

  def for_tag
    name
  end

  def selected
    code || value
  end

  def value=(code)
    if code&.size == 2
      self.external_id = code
      super(APIGeoService.country_name(code, locale: 'FR'))
    elsif code.blank?
      self.external_id = nil
      super(nil)
    elsif code != value
      self.external_id = APIGeoService.country_code(code)
      super(code)
    end
  end

  def code
    external_id || APIGeoService.country_code(value)
  end

  def name
    if external_id.present?
      APIGeoService.country_name(external_id)
    else
      value.present? ? value.to_s : ''
    end
  end
end
