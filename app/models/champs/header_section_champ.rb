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
class Champs::HeaderSectionChamp < Champ
  def level
    if parent.present?
      header_section_level_value.to_i + parent.current_section_level(dossier.revision)
    elsif header_section_level_value
      header_section_level_value.to_i
    else
      0
    end
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def libelle_with_section_index?
    libelle =~ /^\d/
  end

  def section_index
    sections.index(self) + 1
  end
end
