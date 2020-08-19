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
class Champs::CodePostalDePolynesieChamp < Champs::TextChamp
  def self.options
    ApiGeo::API.codes_postaux_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
