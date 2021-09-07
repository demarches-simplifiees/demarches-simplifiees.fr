# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::PaysChamp < Champs::TextChamp
  def localized_value
    if external_id
      I18nData.countries(I18n.locale)[external_id].to_s
    else
      value.present? ? value.to_s : ''
    end
  end

  def to_s
    localized_value
  end

  def for_tag
    localized_value
  end
end
