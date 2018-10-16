class Champs::DepartementChamp < Champs::TextChamp
  def self.departements
    JSON.parse(ApiGeo::API.departements).map { |liste| "#{liste['code']} - #{liste['nom']}" }.push('99 - Étranger')
  end
end
