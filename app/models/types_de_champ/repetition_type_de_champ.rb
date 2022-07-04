class TypesDeChamp::RepetitionTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def build_champ(params)
    revision = params[:revision]
    champ = super
    champ.add_row(revision) if @type_de_champ.mandatory?
    champ
  end

  def estimated_fill_duration(revision)
    estimated_rows_in_repetition = 2.5
    estimated_row_duration = revision
      .children_of(@type_de_champ)
      .map { |child_tdc| child_tdc.estimated_fill_duration(revision) }
      .sum
    estimated_row_duration * estimated_rows_in_repetition
  end

  # We have to truncate the label here as spreadsheets have a (30 char) limit on length.
  def libelle_for_export(index = 0)
    str = "(#{stable_id}) #{libelle}"
    # /\*?[] are invalid Excel worksheet characters
    ActiveStorage::Filename.new(str.delete('[]*?')).sanitized
  end
end
