# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean          default(FALSE)
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::AnnuaireEducationChamp < Champs::TextChamp
  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIEducation::AnnuaireEducationAdapter.new(external_id).to_params
  end

  def update_with_external_data!(data:)
    if data&.is_a?(Hash) && data['nom_etablissement'].present? && data['nom_commune'].present? && data['identifiant_de_l_etablissement'].present?
      update!(
        data: data,
        value: "#{data['nom_etablissement']}, #{data['nom_commune']} (#{data['identifiant_de_l_etablissement']})"
      )
    else
      update!(data: data)
    end
  end
end
