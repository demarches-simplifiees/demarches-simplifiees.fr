# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer          not null
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer          not null
#
class Champs::SiretChamp < Champ
  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def mandatory_blank_and_visible?
    mandatory? && Siret.new(siret: value).invalid?
  end
end
