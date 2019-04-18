class Champs::RepetitionChamp < Champ
  has_many :champs, -> { ordered }, foreign_key: :parent_id, dependent: :destroy

  accepts_nested_attributes_for :champs, allow_destroy: true

  def rows
    champs.group_by(&:row).values
  end

  def add_row(row = 0)
    type_de_champ.types_de_champ.each do |type_de_champ|
      self.champs << type_de_champ.champ.build(row: row)
    end
  end

  def mandatory_and_blank?
    mandatory? && champs.empty?
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end
end
