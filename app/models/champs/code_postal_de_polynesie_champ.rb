class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  def for_export
    if value.present? && (postal_code_city_label = APIGeo::API.commune_by_postal_code_city_label(value))
      [postal_code_city_label[:code_postal].to_s, postal_code_city_label[:commune], postal_code_city_label[:ile], postal_code_city_label[:archipel]]
    else
      ['', '', '', '']
    end
  end

  def self.options
    APIGeo::API.codes_postaux_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
