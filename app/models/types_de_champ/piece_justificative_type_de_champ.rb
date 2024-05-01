class TypesDeChamp::PieceJustificativeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  # pf allows referencing PJs
  # def tags_for_template = [].freeze
end
