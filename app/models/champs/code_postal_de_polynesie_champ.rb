class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  def self.codes_postaux_de_polynesie
    ApiGeo::API.codes_postaux_de_polynesie
  end
end
