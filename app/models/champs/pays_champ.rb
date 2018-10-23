class Champs::PaysChamp < Champs::TextChamp
  def self.pays
    ApiGeo::API.pays.pluck(:nom)
  end
end
