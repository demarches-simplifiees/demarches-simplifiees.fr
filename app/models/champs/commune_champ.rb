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
class Champs::CommuneChamp < Champs::TextChamp
  def for_export
    return nil if value.blank?
    commune_parts = parts
    if commune_parts
      "#{parts[:commune]} (code_postal : #{parts[:code_postal]} / code insee : #{external_id})"
    else
      value
    end
  end

  private

  def parts
    value.match(/(?<commune>.*) \((?<code_postal>\d+)\)/)
  end
end
