class TypesDeChamp::RepetitionTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def build_champ
    champ = super
    champ.add_row
    champ
  end
end
