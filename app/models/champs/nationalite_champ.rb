class Champs::NationaliteChamp < Champs::TextChamp
  def self.nationalites
    ApiGeo::API.nationalites.pluck(:nom)
  end
end
