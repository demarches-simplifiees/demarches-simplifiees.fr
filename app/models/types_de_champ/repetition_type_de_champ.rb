class TypesDeChamp::RepetitionTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def build_champ
    champ = super
    champ.add_row if @type_de_champ.mandatory?
    champ
  end
end
