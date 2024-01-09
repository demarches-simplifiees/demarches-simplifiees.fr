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
