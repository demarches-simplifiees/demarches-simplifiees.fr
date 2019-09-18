class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.communes_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
