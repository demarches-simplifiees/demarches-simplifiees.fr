class Champs::PaysChamp < Champs::TextChamp
  def self.pays
    JSON.parse(ApiGeo::Driver.pays).pluck("nom")
  end
end
