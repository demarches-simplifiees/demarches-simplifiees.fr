# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  parent_id        :bigint
#  type_de_champ_id :integer
#
class Champs::PaysChamp < Champs::TextChamp
  PAYS = JSON.parse(Rails.root.join('app', 'lib', 'api_geo', 'pays.json').read, symbolize_names: true)

  def self.pays
    PAYS.pluck(:nom)
  end

  def self.disabled_options
    pays.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
