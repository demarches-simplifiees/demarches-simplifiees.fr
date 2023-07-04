# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean
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
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def level
    level = type_de_champ.level.present? ? type_de_champ.level.to_i : 1
    level = 1 if level < 1
    level = 3 if level > 3
    level
  end

  def libelle_with_section_index
    if sections&.none?(&:libelle_with_section_index?)
      "#{section_index}. #{libelle}"
    else
      libelle
    end
  end

  def libelle_with_section_index?
    libelle =~ /^\d/
  end

  def section_index
    sections
      .take_while { |c| c != self }
      .push(self)
      .reduce([0, 0, 0]) do |index, c|
      level = c.type_de_champ.level.to_i
      level -= 1 if level > 0
      r = level > 0 ? index[0..(level - 1)] : []
      r << index[level].to_i + 1
    end.reject(&:zero?).join('.')
  end
end
