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
class Champs::HeaderSectionChamp < Champ
  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def section_index
    siblings
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      .index(self) + 1
  end
end
