class Champs::PaysChamp < Champs::TextChamp
  def self.pays
    JSON.parse(Carto::GeoAPI::Driver.pays).pluck("nom")
  end
end
