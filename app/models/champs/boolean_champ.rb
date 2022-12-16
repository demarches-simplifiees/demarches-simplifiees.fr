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
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::BooleanChamp < Champ
  def search_terms
    if true?
      [libelle]
    end
  end

  def to_s
    processed_value
  end

  def for_tag
    processed_value
  end

  def for_export
    processed_value
  end

  def true?
    raise NotImplemented
  end

  def for_api_v2
    true? ? 'true' : 'false'
  end

  private

  def processed_value
    true? ? 'Oui' : 'Non'
  end
end
