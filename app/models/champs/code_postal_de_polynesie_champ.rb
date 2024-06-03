class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
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
end
