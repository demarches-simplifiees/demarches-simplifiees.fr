class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def self.communes_de_polynesie
    ApiGeo::API.communes_de_polynesie
  end
end
