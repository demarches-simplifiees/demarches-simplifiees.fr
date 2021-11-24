class TypesDeChamp::RepetitionTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def build_champ
    champ = super
    champ.add_row if @type_de_champ.mandatory?
    champ
  end

  # We have to truncate the label here as spreadsheets have a (30 char) limit on length.
  def libelle_for_export(index = 0)
    str = "(#{stable_id}) #{libelle}"
    # /\*?[] are invalid Excel worksheet characters
    ActiveStorage::Filename.new(str.delete('[]*?')).sanitized
  end
end
