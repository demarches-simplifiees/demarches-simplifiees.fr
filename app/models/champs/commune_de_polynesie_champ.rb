class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def for_export
    if value.present? && (city_postal_code = APIGeo::API.commune_by_city_postal_code(value))
      [city_postal_code[:commune], city_postal_code[:code_postal].to_s, city_postal_code[:ile], city_postal_code[:archipel]]
    else
      ['', '', '', '']
    end
  end

  def self.options
    APIGeo::API.communes_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
