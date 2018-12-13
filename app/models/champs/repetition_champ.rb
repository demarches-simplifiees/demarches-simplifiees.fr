class Champs::RepetitionChamp < Champ
  has_many :groups, -> { ordered }, foreign_key: :parent_id, class_name: 'ChampGroup', dependent: :destroy

  accepts_nested_attributes_for :groups, allow_destroy: true

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end
end
