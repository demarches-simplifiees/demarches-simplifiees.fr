class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  store_accessor :value_json, :archipel
  before_save :on_value_change, if: :should_refresh_after_value_change?

  def self.options
    APIGeo::API.codes_postaux_de_polynesie
  end

  def island = for_tag(:ile)

  def postal_code = for_tag(:value)

  def name = for_tag(:commune)

  def archipelago = archipel

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
