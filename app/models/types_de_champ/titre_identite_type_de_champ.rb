class TypesDeChamp::TitreIdentiteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  FRANCE_CONNECT = 'france_connect'
  PIECE_JUSTIFICATIVE = 'piece_justificative'

  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end
end
