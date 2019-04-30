class Champs::PaysChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.pays.pluck(:nom)
  end

  def self.disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end
end
