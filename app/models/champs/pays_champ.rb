class Champs::PaysChamp < Champs::TextChamp
  def self.pays
    ApiGeo::API.pays.pluck(:nom)
  end

  def self.disabled_options
    pays.select { |v| (v =~ /^--.*--$/).present? }
  end
end
