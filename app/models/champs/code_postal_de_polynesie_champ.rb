class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  def self.options
    APIGeo::API.codes_postaux_de_polynesie
  end

  def island = for_tag(:ile)

  def postal_code = for_tag(:value)

  def name = for_tag(:commune)

  def archipelago = for_tag(:archipel)

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
