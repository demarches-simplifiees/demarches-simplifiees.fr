class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def for_export(path = :value)
    if value.present? && (city = APIGeo::API.commune_by_city_postal_code(value))
      path = :commune if path == :value
      city[path]
    else
      ''
    end
  end

  def self.options
    APIGeo::API.communes_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
