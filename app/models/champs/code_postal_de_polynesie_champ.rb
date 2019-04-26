class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.codes_postaux_de_polynesie
  end

  def self.disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end
end
