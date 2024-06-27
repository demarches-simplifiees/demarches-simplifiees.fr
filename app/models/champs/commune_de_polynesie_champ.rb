class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def self.options
    APIGeo::API.communes_de_polynesie
  end

  def island = for_tag(:ile)

  def postal_code = for_tag(:code_postal)

  def name = for_tag(:value)

  def archipelago = for_tag(:archipel)

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
