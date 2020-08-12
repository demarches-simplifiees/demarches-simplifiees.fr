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
class Champs::SiretChamp < Champ
  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def mandatory_and_blank?
    mandatory? && Siret.new(siret: value).invalid?
  end
end
