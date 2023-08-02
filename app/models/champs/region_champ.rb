class Champs::RegionChamp < Champs::TextChamp
  validate :value_in_region_names, unless: -> { value.nil? }
  validate :external_id_in_region_codes, unless: -> { external_id.nil? }

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
    else
      self.external_id = APIGeoService.region_code(code)
      super(code)
    end
  end

  private

  def value_in_region_names
    return if value.in?(APIGeoService.regions.pluck(:name))

    errors.add(:value, :not_in_region_names)
  end

  def external_id_in_region_codes
    return if external_id.in?(APIGeoService.regions.pluck(:code))

    errors.add(:external_id, :not_in_region_codes)
  end
end
