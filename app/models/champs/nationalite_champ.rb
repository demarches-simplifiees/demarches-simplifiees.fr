class Champs::NationaliteChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.nationalites.pluck(:nom)
  end

  def self.disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end
end
