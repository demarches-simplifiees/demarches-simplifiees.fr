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
class Champs::YesNoChamp < Champ
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
    value == 'true'
  end

  def for_api_v2
    true? ? 'true' : 'false'
  end

  private

  def processed_value
    true? ? 'Oui' : 'Non'
  end
end
