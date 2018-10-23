class Champs::RegionChamp < Champs::TextChamp
  def self.regions
    ApiGeo::API.regions.sort_by { |e| e[:nom] }.pluck(:nom)
  end
end
