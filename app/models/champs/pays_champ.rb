class Champs::PaysChamp < Champs::TextChamp
  def self.pays
    JSON.parse(ApiGeo::API.pays).pluck("nom")
  end
end
