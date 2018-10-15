class Champs::RegionChamp < Champs::TextChamp
  def self.regions
    JSON.parse(ApiGeo::Driver.regions).sort_by { |e| e['nom'] }.pluck("nom")
  end
end
