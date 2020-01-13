class Champs::PaysChamp < Champs::TextChamp
  PAYS = JSON.parse(Rails.root.join('app', 'lib', 'api_geo', 'pays.json').read, symbolize_names: true)

  def self.pays
    PAYS.pluck(:nom)
  end

  def self.disabled_options
    pays.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
