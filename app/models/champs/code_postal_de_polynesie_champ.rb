class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  store_accessor :value_json, :archipel
  before_save :on_value_change, if: :should_refresh_after_value_change?

  def for_export(path = :value)
    if value.present? && (city = APIGeo::API.commune_by_postal_code_city_label(value))
      path = :code_postal if path == :value
      city[path]
    else
      ''
    end
  end

  def self.options
    APIGeo::API.codes_postaux_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end

  def archipel?
    archipel.present?
  end

  private

  def on_value_change
    return if value.blank?

    commune = APIGeo::API.commune_by_postal_code_city_label(value)

    if commune.present?
      self.archipel = commune[:archipel]
    else
      self.archipel = nil
    end
  end

  def should_refresh_after_value_change?
    !archipel? || value_changed?
  end
end
