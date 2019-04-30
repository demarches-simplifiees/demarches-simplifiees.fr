class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.communes_de_polynesie
  end

  def self.disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end
end
