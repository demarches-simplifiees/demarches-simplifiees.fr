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
class Champs::HeaderSectionChamp < Champ
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def libelle_with_section_index
    if libelle_with_section_index? || siblings.any?(&:libelle_with_section_index?)
      libelle
    else
      "#{section_index}. #{libelle}"
    end
  end

  private

  def libelle_with_section_index?
    libelle =~ /^\d/
  end

  def section_index
    siblings
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      .index(self) + 1
  end
end
